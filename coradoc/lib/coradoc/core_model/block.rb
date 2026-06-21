# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Generic block model
    #
    # Represents all block-level elements in a format-neutral way.
    # Typed subclasses (SourceBlock, QuoteBlock, etc.) express their
    # semantic identity via the class hierarchy — the class IS the type.
    # Generic Block instances use block_semantic_type for typing.
    class Block < Base
      attribute :children, Base, collection: true

      include ChildrenContent

      class << self
        def semantic_type
          nil
        end
      end

      def resolve_semantic_type
        self.class.semantic_type || block_semantic_type&.to_sym
      end

      # Derived element_type string for backward compatibility.
      # Returns the semantic type as a string, derived from the class
      # or block_semantic_type.
      def element_type
        resolve_semantic_type&.to_s
      end

      # @!attribute block_semantic_type
      #   @return [String, nil] semantic type for generic Block instances.
      #     Typed subclasses should not override this — use the class instead.
      attribute :block_semantic_type, :string

      # @!attribute delimiter_type
      #   @return [String, nil] raw delimiter for round-trip fidelity.
      #     Format-specific; CoreModel does NOT derive semantics from this.
      attribute :delimiter_type, :string

      # @!attribute content
      #   @return [String, nil] the block's text content (simple string)
      #     For mixed content with inline elements, use children instead.
      attribute :content, :string

      # @!attribute lines
      #   @return [Array<String>, nil] individual lines of content
      attribute :lines, :string, collection: true

      # @!attribute language
      #   @return [String, nil] language identifier for source code blocks
      attribute :language, :string

      # @!attribute callouts
      #   @return [Array<Callout>] callout annotations attached to this
      #     block. Empty for most block types; populated by format gems
      #     when AsciiDoc-style `<N>` annotations follow a verbatim block.
      attribute :callouts, Callout, collection: true, default: -> { [] }

      private

      def comparable_attributes
        super + %i[block_semantic_type content callouts]
      end
    end
  end
end
