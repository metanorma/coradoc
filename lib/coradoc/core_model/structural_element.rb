# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Base class for structural elements
    #
    # Represents document structure elements that organize content:
    # - Sections (= Title, == Title, === Title, etc.)
    # - Headers
    # - Document divisions
    # - Preamble
    #
    # Structural elements can contain other elements (blocks, lists, etc.)
    # and can be nested hierarchically to represent document structure.
    #
    # This is a base class that can be extended in future phases to handle
    # schema-specific structural requirements.
    #
    # @example Creating a section
    #   section = CoreModel::StructuralElement.new(
    #     element_type: "section",
    #     level: 1,
    #     title: "Introduction",
    #     id: "introduction"
    #   )
    #
    # @example Creating a nested section structure
    #   subsection = CoreModel::StructuralElement.new(
    #     element_type: "section",
    #     level: 2,
    #     title: "Background"
    #   )
    #   section = CoreModel::StructuralElement.new(
    #     element_type: "section",
    #     level: 1,
    #     title: "Introduction",
    #     children: [subsection]
    #   )
    class StructuralElement < Base
      # @!attribute element_type
      #   @return [String, nil] type of structural element
      #     (e.g., 'section', 'header', 'preamble', 'division')
      attribute :element_type, :string

      # @!attribute level
      #   @return [Integer, nil] hierarchical level (1-6 for sections)
      attribute :level, :integer

      # @!attribute content
      #   @return [String, nil] text content of the element
      attribute :content, :string

      # @!attribute children
      #   @return [Array<Base>, nil] child elements (sections, blocks, etc.)
      attribute :children, Base, collection: true

      private

      # Attributes to compare for semantic equivalence
      #
      # Structural elements are semantically equivalent if they have the
      # same type, level, title, and children. The id is not compared
      # because it's often auto-generated and doesn't affect semantics.
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        # Don't include id from super, only title
        [:title] + %i[element_type level children]
      end
    end
  end
end
