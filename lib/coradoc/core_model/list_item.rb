# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a list item in AsciiDoc
    #
    # List items can contain text content, nested lists, and attached blocks.
    # They support various marker types (asterisk, dash, numbered, etc.) and
    # can have different nesting levels.
    #
    # @example Creating a simple list item
    #   item = ListItem.new(
    #     marker: "*",
    #     content: "First item"
    #   )
    #
    # @example Creating a list item with nested content
    #   item = ListItem.new(
    #     marker: "*",
    #     content: "Item with nested list",
    #     nested_list: nested_list_block,
    #     children: [attached_block]
    #   )
    class ListItem < Base
      # @!attribute marker
      #   @return [String] the list marker (*, -, 1., etc.)
      attribute :marker, :string

      # @!attribute content
      #   @return [String] the text content of the list item
      attribute :content, :string

      # Raw Ruby attributes for complex nested structures
      # Not serialized via Lutaml::Model - use for in-memory processing

      # @!attribute nested
      #   @return [ListBlock, nil] nested list block if present
      attr_reader :nested

      # @!attribute children
      #   @return [Array] array of attached blocks/elements (mixed content)
      attr_reader :children

      # Initialize with optional nested structure support
      # @param args [Hash] initialization arguments
      def initialize(args = {})
        @nested = args.delete(:nested) || args.delete(:nested_list)
        @children = args.delete(:children) || []
        super(args)
      end

      # Alias for backward compatibility
      alias nested_list nested

      # Get content for rendering, preferring children over content
      # When children are all plain strings, use the content attribute instead
      # since it already has proper spacing between lines.
      # @return [Array, String, nil] content to render
      def renderable_content
        return content if children.nil? || children.none?
        return content if content && children.all?(String)

        children
      end

      # Convert to hash representation
      #
      # @return [Hash] hash representation of the list item
      def to_h
        {
          marker: marker,
          content: content,
          nested_list: nested&.to_h,
          children: children&.map { |child| child.respond_to?(:to_h) ? child.to_h : child }
        }.compact
      end

      # Create from hash
      #
      # @param hash [Hash] hash representation
      # @return [ListItem] new list item instance
      def self.from_h(hash)
        new(
          marker: hash[:marker],
          content: hash[:content],
          nested: hash[:nested_list],
          children: hash[:children] || []
        )
      end

      # Override semantic equivalence to handle nested structures properly
      def semantically_equivalent?(other)
        return false unless other.is_a?(self.class)
        return false unless content == other.content

        # Compare nested lists if present
        if nested || other.nested
          return false if nested.nil? != other.nested.nil?
          return false if nested && !lists_equivalent?(nested, other.nested)
        end

        # Compare children if present
        if children || other.children
          return false if children.nil? != other.children.nil?
          return false if children && !arrays_equivalent?(children, other.children)
        end

        true
      end

      private

      # Compare two list blocks for equivalence
      def lists_equivalent?(list1, list2)
        # Both should be ListBlock objects or compatible
        return true if list1 == list2
        return false if list1.nil? || list2.nil?

        # Check if both are ListBlock instances
        if list1.is_a?(Coradoc::CoreModel::ListBlock) &&
           list2.is_a?(Coradoc::CoreModel::ListBlock)
          list1.semantically_equivalent?(list2)
        elsif list1.instance_of?(::Coradoc::CoreModel::ListBlock) &&
              list2.instance_of?(::Coradoc::CoreModel::ListBlock)
          # Serialized by Lutaml - compare as objects
          list1.marker_type == list2.marker_type &&
            list1.items.to_a == list2.items.to_a
        else
          list1 == list2
        end
      end

      # Compare two arrays for equivalence
      def arrays_equivalent?(arr1, arr2)
        return false unless arr1.size == arr2.size

        arr1.zip(arr2).all? { |a, b| a == b }
      end
    end
  end
end
