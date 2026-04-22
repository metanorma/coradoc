# frozen_string_literal: true

require_relative 'base'
require_relative '../parser_util'

module Coradoc
  module Markdown
    # Represents an Inline Attribute List (IAL) or Attribute List Definition (ALD)
    #
    # IAL syntax: {:.class #id key="value"}
    # ALD syntax: {:name: #id .class key="value"}
    #
    # Examples:
    #   {:.highlight} - adds class "highlight"
    #   {#introduction} - sets id to "introduction"
    #   {:key="value"} - sets attribute key="value"
    #   {:name: #id .class} - defines ALD named "name"
    #
    class AttributeList < Base
      attribute :id, :string
      attribute :classes, :string, collection: true, default: []
      attribute :attributes, :hash, default: {}
      attribute :name, :string # For ALD - the reference name

      # Parse an IAL string into an AttributeList
      # @param str [String] The IAL string (e.g., '{:.class #id key="val"}')
      # @return [AttributeList] Parsed attribute list
      def self.parse(str)
        return nil if str.nil? || str.empty?

        # Remove surrounding braces
        content = str.strip.gsub(/\A\{?:?|\}?\z/, '')

        attr_list = new

        # Check for ALD (has a name before colon)
        if content =~ /\A(\w+):\s*/
          attr_list.name = ::Regexp.last_match(1)
          content = ::Regexp.last_match.post_match
        end

        # Parse the content
        parse_attributes(content, attr_list)

        attr_list
      end

      # Merge another AttributeList into this one
      # @param other [AttributeList] The other attribute list to merge
      # @return [AttributeList] self for chaining
      def merge!(other)
        return self unless other

        self.id = other.id if other.id
        self.classes = (classes + other.classes).uniq
        self.attributes = attributes.merge(other.attributes)
        self
      end

      # Create a merged copy
      # @param other [AttributeList] The other attribute list to merge
      # @return [AttributeList] New merged attribute list
      def merge(other)
        dup.merge!(other)
      end

      # Check if this has any attributes
      # @return [Boolean]
      def empty?
        id.nil? && classes.empty? && attributes.empty?
      end

      # Convert to Markdown IAL syntax
      # @return [String]
      def to_md
        return '' if empty?

        parts = []
        parts << "##{id}" if id
        parts += classes.map { |c| ".#{c}" }
        parts += attributes.map { |k, v| %(#{k}="#{v}") }

        "{:#{parts.join(' ')}}"
      end

      def self.parse_attributes(content, attr_list)
        # Use shared IalParser for consistent parsing
        ParserUtil::IalParser.tokenize(content).each do |token|
          case token[:type]
          when :class
            attr_list.classes << token[:value]
          when :id
            attr_list.id = token[:value]
          when :attribute
            attr_list.attributes[token[:key]] = token[:value]
          end
        end
      end
    end
  end
end
