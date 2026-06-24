# frozen_string_literal: true

module Coradoc
  module Mirror
    # OCP-compliant registry for Mirror node → CoreModel transformation.
    #
    # Adding support for a new Mirror node type is purely additive:
    #
    #   module ReverseBuilder
    #     class Figure < Base
    #       registers 'figure'
    #
    #       def build(node)
    #         CoreModel::Figure.new(children: context.build_content(node))
    #       end
    #     end
    #   end
    #
    # No edits to MirrorToCoreModel or any other existing class. The
    # registry is the single source of truth for "which type string maps
    # to which builder" (MECE).
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
        def build_content(node)        = context.build_content(node)
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
    end
  end
end
