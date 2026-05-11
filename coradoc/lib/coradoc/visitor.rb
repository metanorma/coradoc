# frozen_string_literal: true

module Coradoc
  # Document visitor pattern for traversing and processing document trees.
  #
  # The visitor pattern enables clean separation of document traversal logic
  # from processing logic. Visitors can be used for:
  # - Document transformation
  # - Content extraction
  # - Validation
  # - Custom rendering
  #
  # @example Basic visitor
  #   class WordCounter < Coradoc::Visitor::Base
  #     attr_reader :count
  #
  #     def initialize
  #       @count = 0
  #     end
  #
  #     def visit_block(block)
  #       @count += block.content.to_s.split.length if block.content
  #       super
  #     end
  #   end
  #
  #   counter = WordCounter.new
  #   document.accept(counter)
  #   puts counter.count
  #
  module Visitor
    # Registry mapping CoreModel classes to visitor method names.
    # CoreModel types self-register via register_visitor on load.
    DISPATCH_TABLE = {} # rubocop:disable Style/MutableConstant

    # Register a CoreModel class to a visitor method name.
    # Called during CoreModel type definition.
    def self.register_visitor(klass, method_name)
      DISPATCH_TABLE[klass] = method_name
    end

    # Base class for document visitors.
    #
    # Provides default traversal behavior for all CoreModel types.
    # Override specific visit_* methods to customize behavior.
    class Base
      # Visit a document element (dispatch method)
      # @param element [CoreModel::Base] Element to visit
      # @return [void]
      def visit(element)
        return if element.nil?

        method_name = DISPATCH_TABLE[element.class]
        if method_name
          public_send(method_name, element)
        elsif element.is_a?(Array)
          visit_array(element)
        else
          visit_unknown(element)
        end
      end

      # Visit a structural element (document, section)
      def visit_structural_element(element)
        visit_children(element.children)
      end

      # Visit a block element
      def visit_block(block)
        visit_children(block.children)
      end

      # Visit an inline element
      def visit_inline_element(element)
        visit_children(element.nested_elements)
      end

      # Visit a list block
      def visit_list_block(list)
        visit_children(list.items)
      end

      # Visit a list item
      def visit_list_item(item)
        visit_children(item.children)
      end

      # Visit a table
      def visit_table(table)
        visit_children(table.rows)
      end

      # Visit a table row
      def visit_table_row(row)
        visit_children(row.cells)
      end

      # Visit a table cell
      def visit_table_cell(cell)
        # TableCell typically contains text or nested elements
      end

      # Visit an image
      def visit_image(image)
        # Image is typically a leaf node
      end

      # Visit a term (definition list term)
      def visit_term(term)
        # Term is typically a leaf node
      end

      # Visit an annotation block (admonition)
      def visit_annotation_block(block)
        visit_children(block.children)
      end

      # Visit a footnote
      def visit_footnote(element)
        # Footnote is typically a leaf node
      end

      # Visit a footnote reference
      def visit_footnote_reference(element)
        # FootnoteReference is typically a leaf node
      end

      # Visit an abbreviation
      def visit_abbreviation(element)
        # Abbreviation is typically a leaf node
      end

      # Visit a definition list
      def visit_definition_list(element)
        visit_children(element.items)
      end

      # Visit a definition item
      def visit_definition_item(element)
        # DefinitionItem is typically a leaf node
      end

      # Visit a bibliography
      def visit_bibliography(element)
        visit_children(element.entries)
      end

      # Visit a bibliography entry
      def visit_bibliography_entry(element)
        # BibliographyEntry is typically a leaf node
      end

      # Visit a table of contents
      def visit_toc(element)
        visit_children(element.entries)
      end

      # Visit a TOC entry
      def visit_toc_entry(element)
        visit_children(element.children)
      end

      # Visit metadata
      def visit_metadata(element)
        visit_children(element.entries)
      end

      # Visit a metadata entry
      def visit_metadata_entry(element)
        # MetadataEntry is a leaf node
      end

      # Visit an element attribute
      def visit_element_attribute(element)
        # ElementAttribute is a leaf node
      end

      # Visit an array of elements
      def visit_array(array)
        array.each { |element| visit(element) }
      end

      # Visit an unknown element type
      def visit_unknown(element)
        # Override to handle unknown types
      end

      private

      # Visit children elements
      def visit_children(children)
        children&.each { |child| visit(child) }
      end
    end

    # Visitor that collects matching elements
    class Collector < Base
      attr_reader :items

      def initialize(*types)
        @types = types.flatten
        @items = []
      end

      def match?(element)
        return true if @types.empty?

        @types.any? { |type| element.is_a?(type) }
      end

      def visit(element)
        @items << element if match?(element)
        super
      end
    end

    # Visitor that transforms elements
    class Transformer < Base
      attr_reader :transformer

      def initialize(&block)
        @transformer = block
      end

      def visit(element)
        transformer&.call(element)
        super
      end
    end

    # Visitor that searches for elements matching criteria
    class Finder < Base
      attr_reader :results

      def initialize(&block)
        @predicate = block
        @results = []
      end

      def visit(element)
        @results << element if @predicate&.call(element)
        super
      end

      def first
        @results.first
      end

      def all
        @results
      end
    end

    # Self-register all CoreModel types
    register_visitor CoreModel::StructuralElement, :visit_structural_element
    register_visitor CoreModel::DocumentElement, :visit_structural_element
    register_visitor CoreModel::SectionElement, :visit_structural_element
    register_visitor CoreModel::PreambleElement, :visit_structural_element
    register_visitor CoreModel::HeaderElement, :visit_structural_element
    register_visitor CoreModel::AnnotationBlock, :visit_annotation_block
    register_visitor CoreModel::Block, :visit_block
    register_visitor CoreModel::InlineElement, :visit_inline_element
    register_visitor CoreModel::ListBlock, :visit_list_block
    register_visitor CoreModel::ListItem, :visit_list_item
    register_visitor CoreModel::Table, :visit_table
    register_visitor CoreModel::TableRow, :visit_table_row
    register_visitor CoreModel::TableCell, :visit_table_cell
    register_visitor CoreModel::Image, :visit_image
    register_visitor CoreModel::Term, :visit_term
    register_visitor CoreModel::Footnote, :visit_footnote
    register_visitor CoreModel::FootnoteReference, :visit_footnote_reference
    register_visitor CoreModel::Abbreviation, :visit_abbreviation
    register_visitor CoreModel::DefinitionList, :visit_definition_list
    register_visitor CoreModel::DefinitionItem, :visit_definition_item
    register_visitor CoreModel::Bibliography, :visit_bibliography
    register_visitor CoreModel::BibliographyEntry, :visit_bibliography_entry
    register_visitor CoreModel::Toc, :visit_toc
    register_visitor CoreModel::TocEntry, :visit_toc_entry
    register_visitor CoreModel::Metadata, :visit_metadata
    register_visitor CoreModel::MetadataEntry, :visit_metadata_entry
    register_visitor CoreModel::ElementAttribute, :visit_element_attribute
  end
end
