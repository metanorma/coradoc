# frozen_string_literal: true

module Coradoc
  # Document querying and introspection API.
  #
  # Provides CSS-like selectors for navigating and querying document trees.
  module Query
    # Selector parsing and matching
    class Selector
      attr_reader :element_type, :id, :classes, :attributes, :pseudo_classes

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

      def parse(selector)
        @original = selector.to_s.strip
        return self if @original.empty?

        @original.sub!(/\A([a-z_][a-z0-9_-]*)/i) do |match|
          @element_type = match.downcase
          ''
        end

        @original.sub!(/#([a-z_][a-z0-9_-]*)/i) do
          @id = ::Regexp.last_match(1)
          ''
        end

        @original.gsub!(/\.([a-z_][a-z0-9_-]*)/i) do
          @classes << ::Regexp.last_match(1)
          ''
        end

        @original.gsub!(/\[([^\]]+)\]/) do
          attr_expr = ::Regexp.last_match(1)
          parse_attribute(attr_expr)
          ''
        end

        @original.gsub!(/:([a-z-]+)(?:\(([^)]+)\))?/i) do
          name = ::Regexp.last_match(1).downcase
          arg = ::Regexp.last_match(2)
          @pseudo_classes << { name: name, argument: arg }
          ''
        end

        self
      end

      def matches?(element)
        return false unless element
        return false if @element_type && !type_matches?(element)
        return false if @id && element.id != @id
        return false if @classes.any? && !classes_match?(element)
        return false if @attributes.any? && !attributes_match?(element)

        true
      end

      def matches_pseudo_classes?(element, siblings:, index:)
        @pseudo_classes.all? do |pseudo|
          case pseudo[:name]
          when 'first-child'
            index.zero?
          when 'last-child'
            index == siblings.length - 1
          when 'nth-child'
            n = pseudo[:argument].to_i
            index == n - 1
          when 'only-child'
            siblings.length == 1
          when 'empty'
            empty_element?(element)
          else
            true
          end
        end
      end

      def universal?
        @element_type == '*' || @original == '*'
      end

      private

      def parse_attribute(expr)
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
          @attributes[::Regexp.last_match(1).to_sym] = { operator: :present }
        end
      end

      def type_matches?(element)
        return true if @element_type == '*'

        return element.element_type.to_s.downcase == @element_type.downcase if (element.is_a?(CoreModel::StructuralElement) || element.is_a?(CoreModel::Block)) && element.element_type

        class_name = class_to_query_name(element.class)
        class_name == @element_type
      end

      def class_to_query_name(klass)
        klass.name
             .to_s
             .split('::')
             .last
             .gsub(/([A-Z])/) { "_#{::Regexp.last_match(1).downcase}" }
             .sub(/^_/, '')
             .downcase
      end

      def classes_match?(element)
        element_classes = if element.is_a?(CoreModel::StructuralElement) && element.element_type
                            [element.element_type]
                          elsif element.is_a?(CoreModel::Base)
                            []
                          else
                            extract_role(element)
                          end

        @classes.all? { |c| element_classes.include?(c.downcase) }
      end

      def extract_role(element)
        role = element.public_send(:role)
        role ? role.to_s.split.map(&:downcase) : []
      rescue NoMethodError
        []
      end

      def attributes_match?(element)
        @attributes.all? do |attr_name, condition|
          value = get_attribute_value(element, attr_name)
          match_attribute_condition(value, condition)
        end
      end

      def get_attribute_value(element, attr_name)
        case attr_name
        when :id, :title
          element.public_send(attr_name)
        when :level
          if element.is_a?(CoreModel::StructuralElement)
            element.level
          else
            element.public_send(:level)
          end
        when :element_type
          element.element_type if element.is_a?(CoreModel::StructuralElement) || element.is_a?(CoreModel::Block)
        when :type
          element.type if element.is_a?(CoreModel::AnnotationBlock) || element.is_a?(CoreModel::InlineElement)
        else
          element.public_send(attr_name) if element.is_a?(CoreModel::Base) && element.class.attributes.key?(attr_name)
        end
      rescue NoMethodError
        nil
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
        return true unless element.is_a?(CoreModel::Block) || element.is_a?(CoreModel::StructuralElement)

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
    class ResultSet
      include Enumerable

      attr_reader :elements

      def initialize(elements = [])
        @elements = Array(elements).compact
      end

      def each(&block)
        @elements.each(&block)
      end

      def [](index)
        @elements[index]
      end

      def length
        @elements.length
      end
      alias size length

      def empty?
        @elements.empty?
      end

      def first
        @elements.first
      end

      def last
        @elements.last
      end

      def filter(selector)
        parsed = Selector.parse(selector)
        filtered = @elements.select { |e| parsed.matches?(e) }
        ResultSet.new(filtered)
      end

      def query(selector)
        results = @elements.flat_map do |element|
          Query.query_within(element, selector).to_a
        end
        ResultSet.new(results.uniq)
      end

      def map(&block)
        ResultSet.new(@elements.map(&block))
      end

      def select(&block)
        ResultSet.new(@elements.select(&block))
      end

      def reject(&block)
        ResultSet.new(@elements.reject(&block))
      end

      def to_a
        @elements.dup
      end

      def inspect
        "#<Coradoc::Query::ResultSet count=#{length}>"
      end
    end

    # Query engine for executing selectors
    class Engine
      def self.query(document, selector)
        new.query(document, selector)
      end

      def query(document, selector)
        return ResultSet.new if document.nil? || selector.to_s.strip.empty?

        return query_multiple(document, selector.split(',').map(&:strip)) if selector.include?(',')

        return query_with_combinators(document, selector) if selector.include?('>') || selector.include?(' ')

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

        first_results = query(document, parts[:first])
        return ResultSet.new if first_results.empty?

        first_results.each do |parent|
          find_matching_descendants(parent, parts[:rest]).each do |match|
            results << match
          end
        end

        ResultSet.new(results.uniq)
      end

      def parse_combinator_selector(selector)
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

        siblings = get_children(parent)
        siblings.each_with_index do |child, index|
          case part[:combinator]
          when :child
            results.concat(find_matching_descendants(child, remaining)) if parsed.matches?(child) && pseudo_matches?(
              parsed, child, siblings, index
            )
          when :descendant
            results.concat(find_matching_descendants(child, remaining)) if parsed.matches?(child) && pseudo_matches?(
              parsed, child, siblings, index
            )
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
        Query.get_children(element)
      end
    end

    # Module-level query methods
    class << self
      def query(document, selector)
        Engine.query(document, selector)
      end

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

      def get_children(element)
        return [] unless element

        if element.is_a?(CoreModel::StructuralElement) && element.children&.any?
          element.children
        elsif element.is_a?(CoreModel::Block) && element.content
          Array(element.content).select { |c| c.is_a?(CoreModel::Base) }
        else
          []
        end
      end

      private

      def traverse_children(element, siblings: [], index: 0, &block)
        children = get_children(element)
        children.each_with_index do |child, i|
          yield(child, children, i)
          traverse_children(child, &block)
        end
      end
    end
  end
end
