# frozen_string_literal: true

module Coradoc
  module Mirror
    # Transforms CoreModel documents into ProseMirror-compatible Mirror nodes.
    #
    # Uses a HandlerRegistry for OCP-compliant dispatch: each CoreModel type
    # maps to a handler module/class that produces the corresponding Mirror node.
    class CoreModelToMirror
      attr_reader :registry

      # Typed struct for pending footnote data (model-driven, not hash bags).
      FootnoteData = Struct.new(:id, :ref_id, :number, :content, keyword_init: true)

      # Maps element types to their children accessors.
      COLLECTION_ACCESSORS = {
        CoreModel::ListBlock => :items,
        CoreModel::DefinitionList => :items,
        CoreModel::Table => :rows,
        CoreModel::Bibliography => :entries
      }.freeze

      def initialize(registry: Coradoc::Mirror.default_registry)
        @registry = registry
        @footnote_counter = 0
        @footnotes = []
        @partition_structural = false
      end

      # Read by Handlers::Structural.section to decide whether to emit
      # generic `section` (legacy) or a JS SECTION_TYPE (`clause`, `annex`,
      # etc.) when partition_structural mode is on.
      attr_accessor :partition_structural

      def call(document, partition_structural: false)
        @footnote_counter = 0
        @footnotes = []
        @partition_structural = partition_structural

        content = extract_content(document)
        fn_block = flush_footnotes
        content << fn_block if fn_block

        attrs = build_document_attrs(document)
        Node::Document.new(
          attrs: Node::Document::Attrs.new(title: attrs[:title], id: attrs[:id]),
          content: partition_structural ? wrap_structural(content) : content
        )
      end

      # Partitions flat doc children into [*metadata, preface?, sections?,
      # *bibliography, *trailing] per the @metanorma/mirror JS structural
      # contract. See Partitioner for the bucketing rules.
      #
      # Metadata blocks (frontmatter) are prepended verbatim so consumers
      # like FrontmatterQuery can find them by walking content[0..n], and
      # renderers can skip them via their type ('frontmatter').
      def wrap_structural(children)
        partitioned = Partitioner.partition(children)
        wrapped = []
        wrapped.concat(partitioned[:metadata])
        wrapped << Node::Preamble.new(content: partitioned[:preface]) if partitioned[:preface].any?
        wrapped << Node::Sections.new(content: partitioned[:sections]) if partitioned[:sections].any?
        wrapped.concat(partitioned[:bibliography])
        wrapped.concat(partitioned[:trailing])
        wrapped
      end

      def extract_content(element)
        children = element_children(element)

        if children && !children.empty?
          content = []
          children.each { |child| handle_element(child, content) }
          content.compact
        elsif element_has_text_content?(element)
          process_inline_content(element)
        else
          []
        end
      end

      def process_inline_content(element)
        Handlers::Inline.process(element, context: self)
      end

      def text_node(text, marks: [])
        Node::Text.new(text: text, marks: marks)
      end

      def register_footnote(footnote)
        @footnote_counter += 1
        num = @footnote_counter
        fn_id = footnote.id || "fn-#{num}"
        ref_id = "fn-ref-#{num}"

        fn_content = footnote.content ? [text_node(footnote.content)] : []
        @footnotes << FootnoteData.new(
          id: fn_id, ref_id: ref_id, number: num, content: fn_content
        )

        Node::FootnoteMarker.new(
          attrs: Node::FootnoteMarker::Attrs.new(
            id: fn_id, ref_id: ref_id, number: num
          )
        )
      end

      def resolve_footnote_reference(ref)
        target_id = ref.id
        entry = @footnotes.find { |fn| fn.id == target_id } if target_id

        if entry
          Node::FootnoteMarker.new(
            attrs: Node::FootnoteMarker::Attrs.new(
              id: entry.id,
              ref_id: "fn-ref-#{entry.number}-dup-#{@footnote_counter}",
              number: entry.number
            )
          )
        else
          text_node("[#{target_id || 'footnote'}]")
        end
      end

      def flush_footnotes
        return nil if @footnotes.empty?

        entries = @footnotes.map do |fn|
          Node::FootnoteEntry.new(
            attrs: Node::FootnoteEntry::Attrs.new(
              id: fn.id, ref_id: fn.ref_id, number: fn.number
            ),
            content: fn.content
          )
        end

        @footnotes = []
        Node::Footnotes.new(content: entries)
      end

      private

      def element_has_text_content?(element)
        element.is_a?(CoreModel::Block) &&
          element.content &&
          !element.content.to_s.empty?
      end

      def element_children(element)
        if element.is_a?(Coradoc::CoreModel::HasChildren)
          children = element.children
          return children if children && !children.empty?
        end

        accessor = COLLECTION_ACCESSORS[element.class]
        element.public_send(accessor) if accessor
      end

      def handle_element(element, content)
        result = @registry.handle(element, context: self)
        return unless result

        value, concat = result
        return unless value

        propagate_source_line(value, element)
        concat ? content.concat(Array(value)) : content << value
      end

      # Copy parser-attached source_line from the CoreModel element onto
      # every Mirror node the handler produced. Single touchpoint for the
      # entire CoreModel → Mirror direction — handlers stay focused on
      # per-type mapping and don't repeat this concern (DRY).
      def propagate_source_line(value, element)
        line = element.source_line
        return unless line

        Array(value).each do |node|
          next unless node.is_a?(Node)
          next if node.source_line

          node.source_line = line
        end
      end

      def build_document_attrs(document)
        attrs = {}
        attrs[:title] = document.title if document.title
        attrs[:id] = document.id if document.id

        if document.is_a?(CoreModel::DocumentElement) &&
           document.attributes.is_a?(CoreModel::Metadata)
          document.attributes.entries&.each do |entry|
            attrs[entry.key.to_sym] = entry.value
          end
        end

        attrs
      end
    end
  end
end
