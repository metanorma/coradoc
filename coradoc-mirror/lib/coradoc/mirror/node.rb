# frozen_string_literal: true

require 'json'

module Coradoc
  module Mirror
    # ProseMirror-compatible document node.
    #
    # Every node has a +type+, optional typed attributes, optional +content+
    # (child nodes), and optional +marks+ (inline formatting). Serializes to
    # the canonical ProseMirror JSON format:
    #
    #   { "type": "paragraph", "content": [...], "attrs": {...}, "marks": [...] }
    #
    # Subclasses declare typed attributes via +node_attr+ and a +PM_TYPE+
    # constant for their canonical type string. New node types are added by
    # subclassing Node — no modification of existing code needed (OCP).
    class Node
      PM_TYPE = 'node'

      attr_accessor :content, :marks

      class << self
        def node_attr(*names, default: nil)
          @node_attr_names ||= []
          @node_attr_defaults ||= {}

          names.each do |name|
            @node_attr_names << name
            @node_attr_defaults[name] = default
          end

          attr_accessor(*names)
        end

        def node_attr_names
          @node_attr_names ||= []
        end

        def node_attr_defaults
          @node_attr_defaults ||= {}
        end
      end

      def initialize(type: nil, content: [], marks: [], **attrs)
        @type_override = type
        @content = content || []
        @marks = marks || []

        self.class.node_attr_names.each do |name|
          value = if attrs.key?(name)
                    attrs[name]
                  else
                    default = self.class.node_attr_defaults[name]
                    default.is_a?(Proc) ? default.call : default
                  end
          public_send(:"#{name}=", value)
        end
      end

      def type
        @type_override || self.class::PM_TYPE
      end

      def to_h
        result = { 'type' => type }
        attrs = serialize_attrs
        result['attrs'] = attrs unless attrs.empty?
        result['marks'] = marks.map(&:to_h) unless marks.empty?
        unless content.empty?
          items = content.is_a?(Array) ? content : [content]
          result['content'] = items.map(&:to_h)
        end
        result
      end

      alias to_hash to_h

      def to_json(pretty: false, **options)
        if pretty
          JSON.pretty_generate(to_h, options)
        else
          to_h.to_json(options)
        end
      end

      def to_yaml
        YAML.dump(to_h)
      end

      def self.from_h(hash)
        return nil unless hash

        type_str = hash['type']
        klass = NODES[type_str]

        if klass && klass != self
          klass.from_h(hash)
        else
          base = klass || self
          content = (hash['content'] || []).map { |c| Node.from_h(c) }
          marks = (hash['marks'] || []).map { |m| Mark.from_h(m) }

          attrs = hash['attrs'] || {}
          kwargs = build_kwargs(base, attrs)
          kwargs[:content] = content
          kwargs[:marks] = marks
          kwargs[:type] = type_str if klass.nil?

          base.new(**kwargs)
        end
      end

      def text_content
        return '' unless content

        content.map do |item|
          item.is_a?(Node) ? item.text_content : ''
        end.join
      end

      # ── Node type subclasses ────────────────────────────────────

      class Text < Node
        PM_TYPE = 'text'

        node_attr :text

        def initialize(text: '', **)
          super(**)
          @text = text
        end

        def to_h
          result = super
          result['text'] = text.to_s
          result
        end

        def text_content
          text.to_s
        end

        def self.from_h(hash)
          return nil unless hash

          new(
            text: hash['text'] || '',
            attrs: (hash['attrs'] || {}).transform_keys(&:to_sym),
            marks: (hash['marks'] || []).map { |m| Mark.from_h(m) }
          )
        end
      end

      class Document < Node
        PM_TYPE = 'doc'
        node_attr :title, :id
      end

      class Paragraph < Node
        PM_TYPE = 'paragraph'
      end

      class Heading < Node
        PM_TYPE = 'heading'
        node_attr :level
      end

      class Section < Node
        PM_TYPE = 'section'
        # JS SECTION_TYPES emitted under partition_structural: true. All
        # deserialize to a Section instance with type preserved.
        PM_ALIASES = %w[
          clause annex content_section abstract foreword introduction
          acknowledgements terms definitions references
        ].freeze
        node_attr :title, :id, :level
      end

      class Preamble < Node
        PM_TYPE = 'preface'
      end

      class Sections < Node
        PM_TYPE = 'sections'
      end

      class Header < Node
        PM_TYPE = 'floating_title'
        node_attr :title, :level
      end

      class CodeBlock < Node
        PM_TYPE = 'sourcecode'
        node_attr :language, :title, :passthrough, :text
      end

      class Blockquote < Node
        PM_TYPE = 'quote'
        node_attr :attribution
      end

      class Example < Node
        PM_TYPE = 'example'
        node_attr :title, :id
      end

      class Sidebar < Node
        PM_TYPE = 'sidebar'
        node_attr :title, :id
      end

      class OpenBlock < Node
        PM_TYPE = 'open_block'
      end

      class Verse < Node
        PM_TYPE = 'verse'
        node_attr :attribution
      end

      class HorizontalRule < Node
        PM_TYPE = 'horizontal_rule'
      end

      class BulletList < Node
        PM_TYPE = 'bullet_list'
        node_attr :id, :start
      end

      class OrderedList < Node
        PM_TYPE = 'ordered_list'
        node_attr :id, :start
      end

      class ListItem < Node
        PM_TYPE = 'list_item'
        node_attr :id
      end

      class DefinitionList < Node
        PM_TYPE = 'dl'
        node_attr :id
      end

      class DefinitionTerm < Node
        PM_TYPE = 'dt'
      end

      class DefinitionDescription < Node
        PM_TYPE = 'dd'
      end

      class Image < Node
        PM_TYPE = 'image'
        node_attr :src, :alt, :title, :caption, :width, :height, :inline
      end

      # JS @metanorma/mirror figure node: wraps an Image with an optional
      # Caption child when the AsciiDoc source provides a title.
      class Figure < Node
        PM_TYPE = 'figure'
        node_attr :id, :title
      end

      # Caption child of Figure. Carries the visible title text.
      class Caption < Node
        PM_TYPE = 'caption'
      end

      class Table < Node
        PM_TYPE = 'table'
        node_attr :title, :id, :width
      end

      class TableHead < Node
        PM_TYPE = 'table_head'
      end

      class TableBody < Node
        PM_TYPE = 'table_body'
      end

      class TableRow < Node
        PM_TYPE = 'table_row'
      end

      class TableCell < Node
        PM_TYPE = 'table_cell'
        node_attr :colspan, :rowspan, :alignment, :header
      end

      # Admonition (NOTE, TIP, WARNING, CAUTION, IMPORTANT).
      #
      # The Ruby-side source-of-truth attribute is `admonition_type`. When
      # constructed via `js_shape: true`, #to_h emits `attrs.type` instead,
      # to match the @metanorma/mirror JS contract. Both shapes
      # deserialize transparently via .from_h.
      class Admonition < Node
        PM_TYPE = 'admonition'
        node_attr :admonition_type, :title, :label, :id

        def initialize(js_shape: false, **kwargs)
          super(**kwargs)
          @js_shape = js_shape
        end

        def to_h
          return super unless @js_shape

          hash = super
          attrs = hash['attrs']
          return hash unless attrs.is_a?(Hash) && attrs.key?('admonition_type')

          attrs['type'] = attrs.delete('admonition_type')
          hash
        end

        def self.from_h(hash)
          return nil unless hash

          raw_attrs = hash['attrs'] || {}
          attrs = raw_attrs.dup
          js_shape = attrs.key?('type') && !attrs.key?('admonition_type')
          attrs['admonition_type'] ||= attrs.delete('type') if attrs.key?('type')

          kwargs = build_kwargs(self, attrs)
          kwargs[:content] = (hash['content'] || []).map { |c| Node.from_h(c) }
          kwargs[:marks] = (hash['marks'] || []).map { |m| Mark.from_h(m) }
          kwargs[:js_shape] = js_shape
          new(**kwargs)
        end
      end

      class Bibliography < Node
        PM_TYPE = 'bibliography'
        node_attr :title, :id, :level
      end

      class BibliographyEntry < Node
        PM_TYPE = 'biblio_entry'
        node_attr :anchor_name, :document_id, :url
      end

      class Footnotes < Node
        PM_TYPE = 'footnotes'
      end

      class FootnoteMarker < Node
        PM_TYPE = 'footnote_marker'
        node_attr :id, :ref_id, :number
      end

      class FootnoteEntry < Node
        PM_TYPE = 'footnote_entry'
        node_attr :id, :ref_id, :number
      end

      class Toc < Node
        PM_TYPE = 'toc'
        node_attr :title
      end

      class TocEntry < Node
        PM_TYPE = 'toc_entry'
        node_attr :id, :title, :level
      end

      class ThematicBreak < Node
        PM_TYPE = 'thematic_break'
      end

      class SoftBreak < Node
        PM_TYPE = 'soft_break'
      end

      class GenericBlock < Node
        PM_TYPE = 'generic_block'
        node_attr :semantic_type, :title, :id
      end

      class Frontmatter < Node
        PM_TYPE = 'frontmatter'
        node_attr :schema
        node_attr :data, default: {}
      end

      # Auto-registry: maps PM_TYPE (and any PM_ALIASES) → class for all
      # declared subclasses. Aliases let one Node class deserialize under
      # multiple type strings (e.g. Section is also clause/annex/...).
      NODES = begin
                registry = {}
                constants.each do |name|
                  k = const_get(name)
                  next unless k.is_a?(Class) && k < Node && k::PM_TYPE != 'node'

                  registry[k::PM_TYPE] = k
                  if k.const_defined?(:PM_ALIASES, false)
                    Array(k::PM_ALIASES).each { |alias_type| registry[alias_type] = k }
                  end
                end
                registry.freeze
      end

      private

      def serialize_attrs
        self.class.node_attr_names.each_with_object({}) do |name, hash|
          value = public_send(name)
          hash[name.to_s] = value unless value.nil?
        end
      end

      def self.build_kwargs(klass, attrs)
        return {} if attrs.empty?

        symbolized = attrs.transform_keys(&:to_sym)
        klass.node_attr_names.each_with_object({}) do |name, kwargs|
          kwargs[name] = symbolized[name] if symbolized.key?(name)
        end
      end
      private_class_method :build_kwargs
    end
  end
end
