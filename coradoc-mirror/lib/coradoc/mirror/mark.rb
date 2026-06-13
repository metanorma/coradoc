# frozen_string_literal: true

module Coradoc
  module Mirror
    # ProseMirror-compatible inline mark (formatting annotation).
    #
    # Marks decorate inline text nodes with formatting semantics like
    # bold, italic, link, etc. They are serialized as:
    #
    #   { "type": "bold" }
    #   { "type": "link", "attrs": { "href": "..." } }
    #
    # New mark types are added by subclassing Mark — no modification of
    # existing code needed (OCP).
    class Mark
      PM_TYPE = 'mark'

      class << self
        def mark_attr(*names)
          @mark_attr_names ||= []
          @mark_attr_names |= names
          attr_accessor(*names)
        end

        def mark_attr_names
          @mark_attr_names ||= []
        end
      end

      def initialize(type: nil)
        @type_override = type
        self.class.mark_attr_names.each do |name|
          public_send(:"#{name}=", nil)
        end
      end

      def type
        @type_override || self.class::PM_TYPE
      end

      def to_h
        result = { 'type' => type }
        attrs = serialize_attrs
        result['attrs'] = attrs unless attrs.empty?
        result
      end

      alias to_hash to_h

      def to_json(**options)
        to_h.to_json(options)
      end

      def self.from_h(hash)
        return nil unless hash

        type_str = hash['type']
        mark_class = MARKS[type_str]

        if mark_class && mark_class != self
          mark_class.from_h(hash)
        else
          attrs = hash['attrs'] || {}
          base = mark_class || self
          kwargs = build_kwargs(base, attrs)
          kwargs[:type] = type_str if mark_class.nil?
          base.new(**kwargs)
        end
      end

      # ── Mark type subclasses ────────────────────────────────────

      class Bold < Mark
        PM_TYPE = 'bold'
      end

      class Italic < Mark
        PM_TYPE = 'italic'
      end

      class Monospace < Mark
        PM_TYPE = 'code'
      end

      class Underline < Mark
        PM_TYPE = 'underline'
      end

      class Strikethrough < Mark
        PM_TYPE = 'strikethrough'
      end

      class Subscript < Mark
        PM_TYPE = 'subscript'
      end

      class Superscript < Mark
        PM_TYPE = 'superscript'
      end

      class Highlight < Mark
        PM_TYPE = 'highlight'
      end

      class Link < Mark
        PM_TYPE = 'link'
        mark_attr :href

        def initialize(href: nil)
          super()
          @href = href
        end

        def self.from_h(hash)
          return nil unless hash

          attrs = hash['attrs'] || {}
          new(href: attrs['href'])
        end
      end

      class CrossReference < Mark
        PM_TYPE = 'xref'
        mark_attr :target, :resolved

        def initialize(target: nil, resolved: nil)
          super()
          @target = target
          @resolved = resolved
        end
      end

      class Stem < Mark
        PM_TYPE = 'stem'
        mark_attr :stem_type

        def initialize(stem_type: nil)
          super()
          @stem_type = stem_type
        end
      end

      class Span < Mark
        PM_TYPE = 'span'
        mark_attr :role

        def initialize(role: nil)
          super()
          @role = role
        end
      end

      # Populate and freeze the registry after all subclasses are defined.
      MARKS = begin
                registry = {}
                constants.each do |name|
                  k = const_get(name)
                  next unless k.is_a?(Class) && k < Mark && k::PM_TYPE != 'mark'

                  registry[k::PM_TYPE] = k
                end
                registry.freeze
      end

      private

      def serialize_attrs
        self.class.mark_attr_names.each_with_object({}) do |name, hash|
          value = public_send(name)
          hash[name.to_s] = value unless value.nil?
        end
      end

      def self.build_kwargs(klass, attrs)
        return {} if attrs.empty?

        symbolized = attrs.transform_keys(&:to_sym)
        klass.mark_attr_names.each_with_object({}) do |name, kwargs|
          kwargs[name] = symbolized[name] if symbolized.key?(name)
        end
      end
      private_class_method :build_kwargs
    end
  end
end
