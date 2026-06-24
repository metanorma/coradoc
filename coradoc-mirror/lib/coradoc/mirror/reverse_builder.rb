# frozen_string_literal: true

module Coradoc
  module Mirror
    # OCP-compliant registry for Mirror node -> CoreModel transformation.
    #
    # Adding support for a new Mirror node type is purely additive:
    #
    #   module ReverseBuilder
    #     class Figure < Base
    #       registers 'figure'
    #
    #       def build(node)
    #         CoreModel::Image.new(src: node.src, ...)
    #       end
    #     end
    #   end
    #
    # No edits to MirrorToCoreModel or any other existing class. The
    # registry is the single source of truth for "which type string maps
    # to which builder" (MECE).
    #
    # This file is the autoload target for the ReverseBuilder constant
    # (see coradoc/mirror.rb). All built-in Builder subclasses live here
    # so their `registers` calls run at load time and the REGISTRY is
    # full before any caller references it. Mirror-level mark dispatch
    # lives in MarkReverseBuilder (mark_reverse_builder.rb).
    module ReverseBuilder
      REGISTRY = {}

      module_function

      def register(type, builder_class)
        REGISTRY[type] = builder_class
      end

      def lookup(type)
        REGISTRY[type]
      end

      def registered_types
        REGISTRY.keys
      end

      # Base class for all reverse builders. Subclasses register one or
      # more Mirror type strings via `registers` and implement `#build`.
      # Shared helpers (build_content, extract_text, apply_mark, ...) are
      # delegated to the context (a MirrorToCoreModel instance), keeping
      # each builder focused on the per-type mapping only (DRY).
      class Base
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def build(_node)
          raise NotImplementedError,
                "#{self.class} must implement #build(node)"
        end

        # Shared helpers — all delegate to the context (DRY).
        def build_content(node) = context.build_content(node)
        def build_inline_children(node) = context.build_inline_children(node)
        def build_node(node)            = context.build_node(node)
        def extract_text(node)          = context.extract_text(node)
        def apply_mark(inner, mark)     = context.apply_mark(inner, mark)
        def inline_content(element)     = context.inline_content(element)

        class << self
          # DSL: declare which Mirror type strings this builder handles.
          # Multiple strings per builder are allowed (e.g. all JS
          # SECTION_TYPES route to the same SectionElement builder).
          def registers(*types)
            types.each { |t| ReverseBuilder.register(t, self) }
          end
        end
      end

      # ── Structural ──

      class Document < Base
        registers 'doc'

        def build(node)
          attrs = node.attrs
          CoreModel::DocumentElement.new(
            title: attrs&.title,
            id: attrs&.id,
            children: build_content(node)
          )
        end
      end

      # All JS SECTION_TYPES reverse to a generic SectionElement. Style
      # information lives in the original AsciiDoc and is preserved only
      # on the forward side; the reverse side collapses them.
      class Section < Base
        registers 'section', 'clause', 'annex', 'content_section',
                  'abstract', 'foreword', 'introduction',
                  'acknowledgements', 'terms', 'definitions', 'references'

        def build(node)
          attrs = node.attrs
          CoreModel::SectionElement.new(
            title: attrs&.title,
            level: attrs&.level,
            id: attrs&.id,
            children: build_content(node)
          )
        end
      end

      class Header < Base
        registers 'floating_title', 'heading'

        def build(node)
          attrs = node.attrs
          CoreModel::HeaderElement.new(
            title: attrs&.title,
            level: attrs&.level,
            children: build_content(node)
          )
        end
      end

      class Preamble < Base
        registers 'preface'

        def build(node)
          CoreModel::PreambleElement.new(children: build_content(node))
        end
      end

      # `sections` is a structural container only — unwrap directly into
      # an array. MirrorToCoreModel#build_content flattens arrays.
      class Sections < Base
        registers 'sections'

        def build(node)
          build_content(node)
        end
      end

      # ── Blocks ──

      class Paragraph < Base
        registers 'paragraph'

        def build(node)
          CoreModel::ParagraphBlock.new(children: build_inline_children(node))
        end
      end

      class CodeBlock < Base
        registers 'sourcecode'

        def build(node)
          attrs = node.attrs
          CoreModel::SourceBlock.new(
            content: attrs&.text || extract_text(node),
            language: attrs&.language,
            title: attrs&.title
          )
        end
      end

      class Blockquote < Base
        registers 'quote'

        def build(node)
          CoreModel::QuoteBlock.new(
            attribution: node.attrs&.attribution,
            children: build_content(node)
          )
        end
      end

      class Example < Base
        registers 'example'

        def build(node)
          CoreModel::ExampleBlock.new(
            title: node.attrs&.title,
            children: build_content(node)
          )
        end
      end

      class Sidebar < Base
        registers 'sidebar'

        def build(node)
          CoreModel::SidebarBlock.new(
            title: node.attrs&.title,
            children: build_content(node)
          )
        end
      end

      class OpenBlock < Base
        registers 'open_block'

        def build(node)
          CoreModel::OpenBlock.new(children: build_content(node))
        end
      end

      class Verse < Base
        registers 'verse'

        def build(node)
          CoreModel::VerseBlock.new(
            content: extract_text(node),
            attribution: node.attrs&.attribution
          )
        end
      end

      class HorizontalRule < Base
        registers 'horizontal_rule', 'thematic_break'

        def build(_node)
          CoreModel::HorizontalRuleBlock.new
        end
      end

      class Frontmatter < Base
        registers 'frontmatter'

        def build(node)
          attrs = node.attrs
          CoreModel::FrontmatterBlock.new(
            schema: attrs&.schema,
            data: FrontmatterTreeToHash.to_hash(attrs&.entries || [])
          )
        end
      end

      class Admonition < Base
        registers 'admonition'

        def build(node)
          CoreModel::AnnotationBlock.new(
            annotation_type: node.attrs&.admonition_type,
            content: extract_text(node)
          )
        end
      end

      # ── Lists ──

      class BulletList < Base
        registers 'bullet_list'

        def build(node)
          items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
          CoreModel::ListBlock.new(marker_type: 'unordered', items: items)
        end
      end

      class OrderedList < Base
        registers 'ordered_list'

        def build(node)
          items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
          CoreModel::ListBlock.new(marker_type: 'ordered', items: items)
        end
      end

      class ListItem < Base
        registers 'list_item'

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join

          CoreModel::ListItem.new(
            content: text,
            children: children,
            nested_list: find_nested_list(node)
          )
        end

        private

        def find_nested_list(node)
          node.content&.each do |child|
            next unless child.is_a?(Node)
            return build_node(child) if LIST_TYPES.include?(child.type)
          end
          nil
        end
      end

      class DefinitionList < Base
        registers 'dl'

        def build(node)
          terms = []
          descriptions = []
          node.content&.each do |child|
            next unless child.is_a?(Node)

            case child.type
            when 'dt' then terms << build_node(child)
            when 'dd' then descriptions << build_node(child)
            end
          end

          items = terms.zip(descriptions).map do |term, desc|
            CoreModel::DefinitionItem.new(
              term: inline_content(term),
              definitions: [inline_content(desc)]
            )
          end

          CoreModel::DefinitionList.new(items: items)
        end
      end

      class InlineText < Base
        registers 'dt', 'dd'

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join
          CoreModel::InlineElement.new(content: text)
        end
      end

      # ── Media ──

      class Image < Base
        registers 'image'

        def build(node)
          attrs = node.attrs
          CoreModel::Image.new(
            src: attrs&.src,
            alt: attrs&.alt,
            title: attrs&.title,
            caption: attrs&.caption,
            width: attrs&.width,
            height: attrs&.height
          )
        end
      end

      # JS @metanorma/mirror `figure` wraps an image plus an optional
      # caption. Reverse: collapse back to a single CoreModel::Image,
      # promoting the caption child to `caption:` if present.
      class Figure < Base
        registers 'figure'

        def build(node)
          image_child = node.content&.find { |c| c.is_a?(Node) && c.type == 'image' }
          return nil unless image_child

          image = build_node(image_child)
          caption = extract_caption(node)
          image.caption = caption if caption && !image.caption
          image
        end

        private

        def extract_caption(node)
          caption_node = node.content&.find { |c| c.is_a?(Node) && c.type == 'caption' }
          return nil unless caption_node

          extract_text(caption_node)
        end
      end

      # Caption only appears as a Figure child. If encountered standalone,
      # extract its text as an inline element so it isn't lost.
      class Caption < Base
        registers 'caption'

        def build(node)
          CoreModel::InlineElement.new(content: extract_text(node))
        end
      end

      # ── Tables ──

      class Table < Base
        registers 'table'

        def build(node)
          rows = []
          node.content&.each do |child|
            next unless child.is_a?(Node)
            next unless %w[table_head table_body].include?(child.type)

            child.content&.each do |row_node|
              rows << build_node(row_node) if row_node.is_a?(Node)
            end
          end

          CoreModel::Table.new(title: node.attrs&.title, rows: rows)
        end
      end

      class TableHead < Base
        registers 'table_head'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end

      class TableBody < Base
        registers 'table_body'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end

      class TableRow < Base
        registers 'table_row'

        def build(node)
          cells = build_content(node).select { |c| c.is_a?(CoreModel::TableCell) }
          CoreModel::TableRow.new(cells: cells)
        end
      end

      class TableCell < Base
        registers 'table_cell'

        def build(node)
          attrs = node.attrs
          CoreModel::TableCell.new(
            content: extract_text(node),
            header: attrs&.header || false,
            colspan: attrs&.colspan,
            rowspan: attrs&.rowspan,
            alignment: attrs&.alignment
          )
        end
      end

      # ── Bibliography ──

      class Bibliography < Base
        registers 'bibliography'

        def build(node)
          entries = build_content(node).select { |c| c.is_a?(CoreModel::BibliographyEntry) }
          CoreModel::Bibliography.new(title: node.attrs&.title, entries: entries)
        end
      end

      class BiblioEntry < Base
        registers 'biblio_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::BibliographyEntry.new(
            anchor_name: attrs&.anchor_name,
            document_id: attrs&.document_id,
            ref_text: extract_text(node)
          )
        end
      end

      # ── Footnotes ──

      # The `footnotes` block is a structural trailing container; it has
      # no CoreModel equivalent (each entry is built separately). Returns
      # nil so build_content filters it out.
      class Footnotes < Base
        registers 'footnotes'

        def build(_node)
          nil
        end
      end

      class FootnoteEntry < Base
        registers 'footnote_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::Footnote.new(id: attrs&.id, content: extract_text(node))
        end
      end

      # Inline footnote marker (JS `footnote_marker`). The CoreModel
      # FootnoteReference holds the same id/ref/number triple.
      class FootnoteMarker < Base
        registers 'footnote_marker'

        def build(node)
          attrs = node.attrs
          CoreModel::FootnoteReference.new(
            id: attrs&.id,
            reference: attrs&.ref_id,
            number: attrs&.number
          )
        end
      end

      # ── TOC ──

      class Toc < Base
        registers 'toc'

        def build(_node)
          CoreModel::Toc.new
        end
      end

      class TocEntry < Base
        registers 'toc_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::TocEntry.new(id: attrs&.id, title: attrs&.title)
        end
      end

      # ── Inline ──

      class Text < Base
        registers 'text'

        def build(node)
          text = node.text || ''
          marks = node.marks || []

          return CoreModel::TextContent.new(text: text) if marks.empty?

          marks.reduce(CoreModel::TextContent.new(text: text)) do |current, mark|
            apply_mark(current, mark)
          end
        end
      end

      class SoftBreak < Base
        registers 'soft_break'

        def build(_node)
          CoreModel::LineBreakElement.new
        end
      end

      # Catch-all for unrecognized block types emitted by the forward
      # direction (`Node::GenericBlock`). Preserves the semantic_type so
      # downstream consumers can dispatch on it.
      class GenericBlock < Base
        registers 'generic_block'

        def build(node)
          attrs = node.attrs
          CoreModel::Block.new(
            block_semantic_type: attrs&.semantic_type || 'generic',
            title: attrs&.title,
            id: attrs&.id,
            content: extract_text(node)
          )
        end
      end

      LIST_TYPES = %w[bullet_list ordered_list].freeze
      private_constant :LIST_TYPES

      # Walks a typed FrontmatterEntry / FrontmatterValue tree and
      # rebuilds the CoreModel `data` hash. Inverse of
      # Handlers::Frontmatter.build_value.
      module FrontmatterTreeToHash
        module_function

        def to_hash(entries)
          entries.each_with_object({}) do |entry, result|
            result[entry.key] = unwrap_value(entry.value)
          end
        end

        def unwrap_value(value)
          case value.value_type
          when 'map' then to_hash(value.entries || [])
          when 'array' then (value.items || []).map { |v| unwrap_value(v) }
          when 'integer'  then value.integer_value
          when 'float'    then value.float_value
          when 'boolean'  then value.boolean_value
          when 'date'     then value.date_value
          when 'datetime' then value.datetime_value
          when 'symbol'   then value.symbol_value&.to_sym
          when 'nil'      then nil
          else value.string_value
          end
        end
      end
    end
  end
end
