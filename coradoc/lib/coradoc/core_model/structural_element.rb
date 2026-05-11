# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Base class for structural elements
    #
    # Represents document structure elements that organize content.
    # Typed subclasses (SectionElement, DocumentElement, etc.) express
    # their role via the class hierarchy — the class IS the type.
    #
    # Structural elements can contain other elements (blocks, lists, etc.)
    # and can be nested hierarchically to represent document structure.
    class StructuralElement < Base
      # @!attribute level
      #   @return [Integer, nil] hierarchical level (1-6 for sections)
      attribute :level, :integer

      # @!attribute content
      #   @return [String, nil] text content of the element
      attribute :content, :string

      # @!attribute children
      #   @return [Array<Base>, nil] child elements (sections, blocks, etc.)
      attribute :children, Base, collection: true

      # @!attribute attributes
      #   @return [Metadata, nil] document-level attributes (typed key-value pairs)
      attribute :attributes, Metadata

      def heading_level
        level || 1
      end

      def section? = false
      def document? = false
      def preamble? = false
      def header? = false

      # Derived element_type string for backward compatibility with
      # templates and legacy consumers. Subclasses override this.
      def element_type
        self.class.element_type_name
      end

      class << self
        def element_type_name
          nil
        end
      end

      private

      def comparable_attributes
        [:title] + %i[level children]
      end
    end

    # Root document element
    class DocumentElement < StructuralElement
      def document? = true

      class << self
        def element_type_name = 'document'
      end
    end

    # Section with a heading at a specific level
    class SectionElement < StructuralElement
      def section? = true

      class << self
        def element_type_name = 'section'
      end
    end

    # Preamble content before the first section heading
    class PreambleElement < StructuralElement
      def preamble? = true

      class << self
        def element_type_name = 'preamble'
      end
    end

    # Header / title block of a document
    class HeaderElement < StructuralElement
      def header? = true

      class << self
        def element_type_name = 'header'
      end
    end
  end
end
