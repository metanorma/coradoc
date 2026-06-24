# frozen_string_literal: true

module Coradoc
  module Mirror
    # OCP-compliant registry for Mirror mark -> CoreModel transformation.
    #
    # This is the mark-level counterpart to ReverseBuilder (which handles
    # node-level dispatch). Adding support for a new mark type is purely
    # additive:
    #
    #   module MarkReverseBuilder
    #     class Concept < Base
    #       registers 'concept'
    #
    #       def build(inner, _mark)
    #         CoreModel::TermElement.new(children: Array(inner))
    #       end
    #     end
    #   end
    #
    # No edits to MirrorToCoreModel#apply_mark or any other existing class.
    module MarkReverseBuilder
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

      # Base class for all mark reverse builders. Subclasses register one
      # mark type string via `registers` and implement `#build(inner, mark)`.
      # `inner` is the already-built CoreModel inline content this mark
      # wraps; `mark` is the source Mirror::Mark (for marks that carry
      # attrs, like `link` reading `mark.href`).
      class Base
        def self.registers(*types)
          types.each { |t| MarkReverseBuilder.register(t, self) }
        end

        def build(_inner, _mark)
          raise NotImplementedError,
                "#{self.class} must implement #build(inner, mark)"
        end
      end

      # ── Simple wraps: typed InlineElement subclass, no attrs ──

      class Bold < Base
        registers 'strong'

        def build(inner, _mark)
          CoreModel::BoldElement.new(children: Array(inner))
        end
      end

      class Italic < Base
        registers 'emphasis'

        def build(inner, _mark)
          CoreModel::ItalicElement.new(children: Array(inner))
        end
      end

      class Monospace < Base
        registers 'code'

        def build(inner, _mark)
          CoreModel::MonospaceElement.new(children: Array(inner))
        end
      end

      class Underline < Base
        registers 'underline'

        def build(inner, _mark)
          CoreModel::UnderlineElement.new(children: Array(inner))
        end
      end

      class Strikethrough < Base
        registers 'strike'

        def build(inner, _mark)
          CoreModel::StrikethroughElement.new(children: Array(inner))
        end
      end

      class Subscript < Base
        registers 'subscript'

        def build(inner, _mark)
          CoreModel::SubscriptElement.new(children: Array(inner))
        end
      end

      class Superscript < Base
        registers 'superscript'

        def build(inner, _mark)
          CoreModel::SuperscriptElement.new(children: Array(inner))
        end
      end

      class Highlight < Base
        registers 'highlight'

        def build(inner, _mark)
          CoreModel::HighlightElement.new(children: Array(inner))
        end
      end

      # ── Marks with attrs ──

      class Link < Base
        registers 'link'

        def build(inner, mark)
          CoreModel::LinkElement.new(target: mark.href, children: Array(inner))
        end
      end

      class CrossReference < Base
        registers 'xref'

        def build(inner, mark)
          CoreModel::CrossReferenceElement.new(
            target: mark.target, children: Array(inner)
          )
        end
      end
    end
  end
end
