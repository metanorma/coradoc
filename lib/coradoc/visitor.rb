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
  # @example Transforming visitor
  #   class UppercaseTransformer < Coradoc::Visitor::Base
  #     def visit_block(block)
  #       block.content = block.content.upcase if block.content.is_a?(String)
  #       super
  #     end
  #   end
  #
  module Visitor
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

        case element
        when CoreModel::StructuralElement
          visit_structural_element(element)
        when CoreModel::Block
          visit_block(element)
        when CoreModel::InlineElement
          visit_inline_element(element)
        when CoreModel::ListBlock
          visit_list_block(element)
        when CoreModel::ListItem
          visit_list_item(element)
        when CoreModel::Table
          visit_table(element)
        when CoreModel::TableRow
          visit_table_row(element)
        when CoreModel::TableCell
          visit_table_cell(element)
        when CoreModel::Image
          visit_image(element)
        when CoreModel::Term
          visit_term(element)
        when CoreModel::AnnotationBlock
          visit_annotation_block(element)
        when Array
          visit_array(element)
        else
          visit_unknown(element)
        end
      end

      # Visit a structural element (document, section)
      # @param element [CoreModel::StructuralElement] Element to visit
      # @return [void]
      def visit_structural_element(element)
        visit_children(element.children) if element.respond_to?(:children)
      end

      # Visit a block element
      # @param block [CoreModel::Block] Block to visit
      # @return [void]
      def visit_block(block)
        visit_children(block.children) if block.respond_to?(:children)
      end

      # Visit an inline element
      # @param element [CoreModel::InlineElement] Element to visit
      # @return [void]
      def visit_inline_element(element)
        visit_children(element.nested_elements) if element.respond_to?(:nested_elements)
      end

      # Visit a list block
      # @param list [CoreModel::ListBlock] List to visit
      # @return [void]
      def visit_list_block(list)
        visit_children(list.items) if list.respond_to?(:items)
      end

      # Visit a list item
      # @param item [CoreModel::ListItem] Item to visit
      # @return [void]
      def visit_list_item(item)
        visit_children(item.children) if item.respond_to?(:children)
      end

      # Visit a table
      # @param table [CoreModel::Table] Table to visit
      # @return [void]
      def visit_table(table)
        visit_children(table.rows) if table.respond_to?(:rows)
      end

      # Visit a table row
      # @param row [CoreModel::TableRow] Row to visit
      # @return [void]
      def visit_table_row(row)
        visit_children(row.cells) if row.respond_to?(:cells)
      end

      # Visit a table cell
      # @param cell [CoreModel::TableCell] Cell to visit
      # @return [void]
      def visit_table_cell(cell)
        # TableCell typically contains text or nested elements
      end

      # Visit an image
      # @param image [CoreModel::Image] Image to visit
      # @return [void]
      def visit_image(image)
        # Image is typically a leaf node
      end

      # Visit a term (definition list term)
      # @param term [CoreModel::Term] Term to visit
      # @return [void]
      def visit_term(term)
        # Term is typically a leaf node
      end

      # Visit an annotation block (admonition)
      # @param block [CoreModel::AnnotationBlock] Block to visit
      # @return [void]
      def visit_annotation_block(block)
        visit_children(block.children) if block.respond_to?(:children)
      end

      # Visit an array of elements
      # @param array [Array] Array to visit
      # @return [void]
      def visit_array(array)
        array.each { |element| visit(element) }
      end

      # Visit an unknown element type
      # @param element [Object] Unknown element
      # @return [void]
      def visit_unknown(element)
        # Override to handle unknown types
      end

      private

      # Visit children elements
      # @param children [Array, nil] Children to visit
      # @return [void]
      def visit_children(children)
        return if children.nil?

        children.each { |child| visit(child) }
      end
    end

    # Visitor that collects matching elements
    #
    # @example Collect all paragraphs
    #   collector = Visitor::Collector.new(CoreModel::Block)
    #   document.accept(collector)
    #   paragraphs = collector.items.select { |b| b.element_type == "paragraph" }
    #
    class Collector < Base
      # @return [Array<CoreModel::Base>] Collected items
      attr_reader :items

      # @param types [Array<Class>, Class] Types to collect (optional, collects all if not specified)
      def initialize(*types)
        @types = types.flatten
        @items = []
      end

      # Check if element should be collected
      # @param element [CoreModel::Base] Element to check
      # @return [Boolean]
      def match?(element)
        return true if @types.empty?

        @types.any? { |type| element.is_a?(type) }
      end

      # Override to collect matching elements
      def visit(element)
        @items << element if match?(element)
        super
      end
    end

    # Visitor that transforms elements
    #
    # @example Transform all blocks
    #   transformer = Visitor::Transformer.new do |element|
    #     if element.is_a?(CoreModel::Block) && element.content.is_a?(String)
    #       element.content = element.content.upcase
    #     end
    #   end
    #   document.accept(transformer)
    #
    class Transformer < Base
      # @return [Proc] Transformation block
      attr_reader :transformer

      # @param block [Proc] Block to apply to each element
      def initialize(&block)
        @transformer = block
      end

      # Apply transformation to element before traversal
      def visit(element)
        transformer&.call(element)
        super
      end
    end

    # Visitor that searches for elements matching criteria
    #
    # @example Find element by ID
    #   finder = Visitor::Finder.new { |e| e.id == "section-1" }
    #   document.accept(finder)
    #   section = finder.first
    #
    class Finder < Base
      # @return [Array<CoreModel::Base>] Found items
      attr_reader :results

      # @param block [Proc] Predicate block for matching
      def initialize(&block)
        @predicate = block
        @results = []
      end

      # Check if element matches and collect it
      def visit(element)
        @results << element if @predicate&.call(element)
        super
      end

      # Get first matching result
      # @return [CoreModel::Base, nil]
      def first
        @results.first
      end

      # Get all matching results
      # @return [Array<CoreModel::Base>]
      def all
        @results
      end
    end
  end
end
