# frozen_string_literal: true

module Coradoc
  # Document querying and introspection API.
  #
  # This module provides CSS-like selectors for navigating and querying
  # document trees. It enables powerful document manipulation patterns.
  #
  # @example Querying documents
  #   doc = Coradoc.parse(adoc_text, format: :asciidoc)
  #
  #   # Find all sections
  #   sections = doc.query('section')
  #
  #   # Find level-2 sections
  #   doc.query('section.level-2').each do |section|
  #     puts section.title
  #   end
  #
  #   # Find paragraphs with specific role
  #   examples = doc.query('[role=example]')
  #
  #   # Complex selectors
  #   doc.query('section > paragraph:first-child')
  #
  module Query
    # Selector parsing and matching
    #
    # Supports CSS-like selectors for document querying:
    # - Element type: `section`, `paragraph`, `table`
    # - Class/level: `.level-2`, `.important`
    # - ID: `#intro`, `#section-1`
    # - Attributes: `[id=intro]`, `[role=example]`, `[level>1]`
    # - Pseudo-classes: `:first-child`, `:last-child`, `:nth-child(2)`
    # - Combinators: `>` (child), space (descendant)
    #
    class Selector
      attr_reader :element_type, :id, :classes, :attributes, :pseudo_classes

      # Parse a selector string
      #
      # @param selector [String] CSS-like selector
      # @return [Selector] Parsed selector object
      def self.parse(selector)
        new.parse(selector)
      end

      def initialize
        @element_type = nil
        @id = nil
        @classes = []
        @attributes = {}
        @pseudo_classes = []
      end

      # Parse a selector string into this object
      #
      # @param selector [String] The selector to parse
      # @return [self]
      def parse(selector)
        @original = selector.to_s.strip
        return self if @original.empty?

        # Parse element type
        @original.sub!(/\A([a-z_][a-z0-9_-]*)/i) do |match|
          @element_type = match.downcase
          ''
        end

        # Parse ID
        @original.sub!(/#([a-z_][a-z0-9_-]*)/i) do
          @id = ::Regexp.last_match(1)
          ''
        end

        # Parse classes
        @original.gsub!(/\.([a-z_][a-z0-9_-]*)/i) do
          @classes << ::Regexp.last_match(1)
          ''
        end

        # Parse attributes
        @original.gsub!(/\[([^\]]+)\]/) do
          attr_expr = ::Regexp.last_match(1)
          parse_attribute(attr_expr)
          ''
        end

        # Parse pseudo-classes
        @original.gsub!(/:([a-z-]+)(?:\(([^)]+)\))?/i) do
          name = ::Regexp.last_match(1).downcase
          arg = ::Regexp.last_match(2)
          @pseudo_classes << { name: name, argument: arg }
          ''
        end

        self
      end

      # Check if an element matches this selector
      #
      # @param element [CoreModel::Base] The element to check
      # @return [Boolean]
      def matches?(element)
        return false unless element

        # Check element type
        return false if @element_type && !type_matches?(element)

        # Check ID
        return false if @id && element_id(element) != @id

        # Check classes/roles
        return false if @classes.any? && !classes_match?(element)

        # Check attributes
        return false if @attributes.any? && !attributes_match?(element)

        true
      end

      # Check pseudo-class conditions
      #
      # @param element [CoreModel::Base] The element to check
      # @param siblings [Array] Sibling elements
      # @param index [Integer] Element's index among siblings
      # @return [Boolean]
      def matches_pseudo_classes?(element, siblings:, index:)
        @pseudo_classes.all? do |pseudo|
          case pseudo[:name]
          when 'first-child'
            index.zero?
          when 'last-child'
            index == siblings.length - 1
          when 'nth-child'
            n = pseudo[:argument].to_i
            index == n - 1 # 1-indexed in CSS
          when 'only-child'
            siblings.length == 1
          when 'empty'
            empty_element?(element)
          else
            true # Unknown pseudo-classes pass
          end
        end
      end

      # Check if selector is universal (*)
      #
      # @return [Boolean]
      def universal?
        @element_type == '*' || @original == '*'
      end

      private

      def parse_attribute(expr)
        # Handle different attribute operators
        case expr
        when /(\w+)\s*=\s*["']?([^"']+)["']?/
          @attributes[::Regexp.last_match(1).to_sym] = {
            operator: :equals,
            value: ::Regexp.last_match(2)
          }
        when /(\w+)\s*~=\s*["']?([^"']+)["']?/
          @attributes[::Regexp.last_match(1).to_sym] = {
            operator: :includes,
            value: ::Regexp.last_match(2)
          }
        when /(\w+)\s*\^=\s*["']?([^"']+)["']?/
          @attributes[::Regexp.last_match(1).to_sym] = {
            operator: :starts_with,
            value: ::Regexp.last_match(2)
          }
        when /(\w+)\s*\$=\s*["']?([^"']+)["']?/
          @attributes[::Regexp.last_match(1).to_sym] = {
            operator: :ends_with,
            value: ::Regexp.last_match(2)
          }
        when /(\w+)\s*\*=\s*["']?([^"']+)["']?/
          @attributes[::Regexp.last_match(1).to_sym] = {
            operator: :contains,
            value: ::Regexp.last_match(2)
          }
        when /(\w+)/
          # Attribute presence check
          @attributes[::Regexp.last_match(1).to_sym] = { operator: :present }
        end
      end

      def type_matches?(element)
        return true if @element_type == '*'

        # First check the element_type attribute if present (for StructuralElement)
        if element.respond_to?(:element_type) && element.element_type && (element.element_type.to_s.downcase == @element_type.downcase)
          return true
        end

        # Then check the class name
        element_type = element.class.name
                              .to_s
                              .split('::')
                              .last
                              .gsub(/([A-Z])/) { "_#{::Regexp.last_match(1).downcase}" }
                              .sub(/^_/, '')
                              .downcase

        element_type == @element_type ||
          element_type.include?(@element_type) ||
          element_type.delete('_').include?(@element_type.delete('_'))
      end

      def element_id(element)
        element.respond_to?(:id) ? element.id : nil
      end

      def classes_match?(element)
        element_classes = if element.respond_to?(:role) && element.role
                            element.role.split.map(&:downcase)
                          elsif element.respond_to?(:classes)
                            Array(element.classes).map(&:downcase)
                          else
                            []
                          end

        @classes.all? { |c| element_classes.include?(c.downcase) }
      end

      def attributes_match?(element)
        @attributes.all? do |attr_name, condition|
          value = get_attribute_value(element, attr_name)
          match_attribute_condition(value, condition)
        end
      end

      def get_attribute_value(element, attr_name)
        case attr_name
        when :id
          element.respond_to?(:id) ? element.id : nil
        when :level
          element.respond_to?(:level) ? element.level : nil
        when :role
          element.respond_to?(:role) ? element.role : nil
        when :type
          element.respond_to?(:type) ? element.type : nil
        else
          element.respond_to?(attr_name) ? element.send(attr_name) : nil
        end
      end

      def match_attribute_condition(value, condition)
        case condition[:operator]
        when :present
          !value.nil?
        when :equals
          value.to_s == condition[:value]
        when :includes
          value.to_s.split.map(&:downcase).include?(condition[:value].downcase)
        when :starts_with
          value.to_s.start_with?(condition[:value])
        when :ends_with
          value.to_s.end_with?(condition[:value])
        when :contains
          value.to_s.include?(condition[:value])
        else
          false
        end
      end

      def empty_element?(element)
        return true unless element.respond_to?(:content)

        content = element.content
        case content
        when String
          content.strip.empty?
        when Array
          content.empty?
        else
          content.nil?
        end
      end
    end

    # Query result set - collection of matched elements
    #
    # Provides array-like access with additional query methods for
    # chaining and further filtering.
    #
    class ResultSet
      include Enumerable

      # @return [Array<CoreModel::Base>] Matched elements
      attr_reader :elements

      # Create a new result set
      #
      # @param elements [Array<CoreModel::Base>] Matched elements
      def initialize(elements = [])
        @elements = Array(elements).compact
      end

      # Iterate over elements
      #
      # @yield [CoreModel::Base] Each matched element
      # @return [Enumerator]
      def each(&block)
        @elements.each(&block)
      end

      # Get element at index
      #
      # @param index [Integer] Element index
      # @return [CoreModel::Base, nil]
      def [](index)
        @elements[index]
      end

      # Number of matched elements
      #
      # @return [Integer]
      def length
        @elements.length
      end
      alias size length

      # Check if result set is empty
      #
      # @return [Boolean]
      def empty?
        @elements.empty?
      end

      # Get first element
      #
      # @return [CoreModel::Base, nil]
      def first
        @elements.first
      end

      # Get last element
      #
      # @return [CoreModel::Base, nil]
      def last
        @elements.last
      end

      # Filter results with an additional selector
      #
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Filtered results
      def filter(selector)
        parsed = Selector.parse(selector)
        filtered = @elements.select { |e| parsed.matches?(e) }
        ResultSet.new(filtered)
      end

      # Query within each element in the result set
      #
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Combined results
      def query(selector)
        results = @elements.flat_map do |element|
          Query.query_within(element, selector).to_a
        end
        ResultSet.new(results.uniq)
      end

      # Map over elements and return new result set
      #
      # @yield [CoreModel::Base] Block to transform elements
      # @return [ResultSet]
      def map(&block)
        ResultSet.new(@elements.map(&block))
      end

      # Select elements matching block
      #
      # @yield [CoreModel::Base] Test block
      # @return [ResultSet]
      def select(&block)
        ResultSet.new(@elements.select(&block))
      end

      # Reject elements matching block
      #
      # @yield [CoreModel::Base] Test block
      # @return [ResultSet]
      def reject(&block)
        ResultSet.new(@elements.reject(&block))
      end

      # Convert to array
      #
      # @return [Array<CoreModel::Base>]
      def to_a
        @elements.dup
      end

      # Pretty print representation
      #
      # @return [String]
      def inspect
        "#<Coradoc::Query::ResultSet count=#{length}>"
      end
    end

    # Query engine for executing selectors
    #
    class Engine
      # Query a document or element
      #
      # @param document [CoreModel::Base] Root document/element
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Matched elements
      def self.query(document, selector)
        new.query(document, selector)
      end

      # Query document with selector
      #
      # @param document [CoreModel::Base] Root element
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Matched elements
      def query(document, selector)
        return ResultSet.new if document.nil? || selector.to_s.strip.empty?

        # Handle comma-separated selectors
        return query_multiple(document, selector.split(',').map(&:strip)) if selector.include?(',')

        # Handle descendant combinator (space) and child combinator (>)
        return query_with_combinators(document, selector) if selector.include?('>') || selector.include?(' ')

        # Simple single selector
        parsed = Selector.parse(selector)
        results = []

        traverse(document) do |element, siblings, index|
          if parsed.matches?(element)
            next if parsed.pseudo_classes.any? && !parsed.matches_pseudo_classes?(element, siblings: siblings,
                                                                                           index: index)

            results << element
          end
        end

        ResultSet.new(results)
      end

      private

      def query_multiple(document, selectors)
        results = selectors.flat_map do |sel|
          query(document, sel).to_a
        end
        ResultSet.new(results.uniq)
      end

      def query_with_combinators(document, selector)
        parts = parse_combinator_selector(selector)
        results = []

        # Find elements matching the first part
        first_results = query(document, parts[:first])
        return ResultSet.new if first_results.empty?

        # For each first match, look for descendants/children
        first_results.each do |parent|
          find_matching_descendants(parent, parts[:rest]).each do |match|
            results << match
          end
        end

        ResultSet.new(results.uniq)
      end

      def parse_combinator_selector(selector)
        # Simple parsing - handles "parent > child" and "parent child"
        if selector.include?(' > ')
          parts = selector.split(' > ', 2)
          { first: parts[0], rest: [{ combinator: :child, selector: parts[1] }] }
        elsif selector.include?(' ')
          parts = selector.split(' ', 2)
          { first: parts[0], rest: [{ combinator: :descendant, selector: parts[1] }] }
        else
          { first: selector, rest: [] }
        end
      end

      def find_matching_descendants(parent, parts)
        return [parent] if parts.empty?

        part = parts.first
        remaining = parts[1..]

        parsed = Selector.parse(part[:selector])
        results = []

        get_children(parent).each_with_index do |child, index|
          siblings = get_children(parent)

          case part[:combinator]
          when :child
            results.concat(find_matching_descendants(child, remaining)) if parsed.matches?(child) && pseudo_matches?(
              parsed, child, siblings, index
            )
          when :descendant
            results.concat(find_matching_descendants(child, remaining)) if parsed.matches?(child) && pseudo_matches?(
              parsed, child, siblings, index
            )
            # Also search deeper
            results.concat(find_matching_descendants(child, parts))
          end
        end

        results
      end

      def pseudo_matches?(parsed, element, siblings, index)
        return true if parsed.pseudo_classes.empty?

        parsed.matches_pseudo_classes?(element, siblings: siblings, index: index)
      end

      def traverse(element, siblings: [], index: 0, &block)
        return unless element

        yield(element, siblings, index)

        children = get_children(element)
        children.each_with_index do |child, i|
          traverse(child, siblings: children, index: i, &block)
        end
      end

      def get_children(element)
        return [] unless element

        case element
        when Coradoc::CoreModel::StructuralElement
          element.children || []
        when Coradoc::CoreModel::Block
          Array(element.content).select { |c| c.is_a?(Coradoc::CoreModel::Base) }
        else
          if element.respond_to?(:children)
            Array(element.children)
          elsif element.respond_to?(:content)
            Array(element.content).select { |c| c.is_a?(Coradoc::CoreModel::Base) }
          else
            []
          end
        end
      end
    end

    # Module-level query methods
    class << self
      # Query a document with a selector
      #
      # @param document [CoreModel::Base] The document to query
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Matched elements
      def query(document, selector)
        Engine.query(document, selector)
      end

      # Query within an element (not including the element itself)
      #
      # @param element [CoreModel::Base] The parent element
      # @param selector [String] CSS-like selector
      # @return [ResultSet] Matched elements
      def query_within(element, selector)
        parsed = Selector.parse(selector)
        results = []

        traverse_children(element) do |child, siblings, index|
          if parsed.matches?(child)
            next if parsed.pseudo_classes.any? && !parsed.matches_pseudo_classes?(child, siblings: siblings,
                                                                                         index: index)

            results << child
          end
        end

        ResultSet.new(results)
      end

      private

      def traverse_children(element, siblings: [], index: 0, &block)
        children = get_children(element)
        children.each_with_index do |child, i|
          yield(child, children, i)
          traverse_children(child, &block)
        end
      end

      def get_children(element)
        return [] unless element

        case element
        when Coradoc::CoreModel::StructuralElement
          element.children || []
        when Coradoc::CoreModel::Block
          Array(element.content).select { |c| c.is_a?(Coradoc::CoreModel::Base) }
        else
          if element.respond_to?(:children)
            Array(element.children)
          elsif element.respond_to?(:content)
            Array(element.content).select { |c| c.is_a?(Coradoc::CoreModel::Base) }
          else
            []
          end
        end
      end
    end
  end
end
