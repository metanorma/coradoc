# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Specialized block for annotations and admonitions
    #
    # Represents annotation blocks that have special semantic meaning:
    # - NOTE
    # - WARNING
    # - CAUTION
    # - IMPORTANT
    # - TIP
    # - Reviewer notes
    # - Sidebar blocks (when used for annotations)
    #
    # This class extends Block to add annotation-specific attributes that
    # distinguish these blocks semantically from generic delimited blocks.
    #
    # @example Creating a NOTE annotation
    #   note = CoreModel::AnnotationBlock.new(
    #     annotation_type: "note",
    #     delimiter_type: "****",
    #     content: "This is important information."
    #   )
    #
    # @example Creating a reviewer note
    #   reviewer = CoreModel::AnnotationBlock.new(
    #     annotation_type: "reviewer",
    #     annotation_label: "john.doe",
    #     delimiter_type: "////",
    #     content: "Please review this section."
    #   )
    class AnnotationBlock < Block
      # @!attribute annotation_type
      #   @return [String, nil] the type of annotation
      #     (e.g., 'note', 'warning', 'reviewer', 'sidebar')
      attribute :annotation_type, :string

      # @!attribute annotation_label
      #   @return [String, nil] optional custom label or identifier
      #     (e.g., reviewer ID, custom note label)
      attribute :annotation_label, :string

      private

      # Attributes to compare for semantic equivalence
      #
      # Annotation blocks are semantically different from generic blocks
      # because they carry additional meaning through annotation_type and
      # annotation_label. Two blocks with different annotation types are
      # not semantically equivalent even if their content is identical.
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        super + %i[annotation_type annotation_label]
      end
    end
  end
end
