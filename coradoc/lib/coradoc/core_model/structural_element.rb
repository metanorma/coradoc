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
      # StructuralElements carry typed block children (sections, paragraphs,
      # etc.) rather than mixed inline content, so they don't include
      # ChildrenContent. HasChildren marks the structural predicate that
      # downstream traversal dispatches on (OCP).
      include HasChildren
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

      def section?
        false
      end

      def document?
        false
      end

      def preamble?
        false
      end

      def header?
        false
      end

      # Override in subclasses that carry document-title semantics.
      # HeaderElement at level 0 represents the document title (`= Title`
      # in AsciiDoc). Consumers that walk the body — TOC builders,
      # section numbering — skip these so the title is not counted as
      # "section 1". Polymorphic dispatch (vs. an is_a? guard at the
      # call site) keeps the predicate open for future subclasses.
      def document_title?
        false
      end

      # Children that count as body content and aren't whitespace-only.
      # Derived from per-node {#body_content?} and {#whitespace_only?}
      # predicates — no central walker, no is_a? switch to maintain.
      def visible_children
        Array(children).select(&:body_content?).reject(&:whitespace_only?)
      end

      # True when the body has no visible content anywhere in its subtree.
      # A document with only frontmatter + comments returns true; a
      # document with one non-whitespace paragraph returns false.
      def empty_body?
        return true if children.nil? || children.empty?

        children.all? do |child|
          next true unless child.body_content?
          next true if child.whitespace_only?
          next child.empty_body? if child.is_a?(StructuralElement)

          false
        end
      end

      # Derived element_type string for backward compatibility with
      # templates and legacy consumers. Subclasses override this.
      def element_type
        self.class.element_type_name
      end

      def self.element_type_name
        nil
      end

      private

      def comparable_attributes
        [:title] + %i[level children]
      end
    end

    # Root document element
    class DocumentElement < StructuralElement
      def document?
        true
      end

      def self.element_type_name
        'document'
      end
    end

    # Section with a heading at a specific level
    class SectionElement < StructuralElement
      def section?
        true
      end

      def self.element_type_name
        'section'
      end
    end

    # Preamble content before the first section heading
    class PreambleElement < StructuralElement
      def preamble?
        true
      end

      def self.element_type_name
        'preamble'
      end
    end

    # Header / title block of a document
    class HeaderElement < StructuralElement
      def header?
        true
      end

      # A level-0 HeaderElement represents the document title (the `= Title`
      # line in AsciiDoc, the `<h1>` in HTML). It is structurally part of
      # the body but semantically the document's title, not a section —
      # section numbering, TOC builders, and other section-aware logic
      # skip these so the title is not counted as "section 1".
      def document_title?
        level.to_i.zero?
      end

      def self.element_type_name
        'header'
      end
    end
  end
end
