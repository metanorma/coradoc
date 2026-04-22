# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a single item within a list
    #
    # A list item can contain:
    # - Simple text content
    # - A nested list
    # - Child elements (paragraphs, blocks, etc.)
    #
    # Note: The nested_list attribute type is set after ListBlock is defined
    # to avoid circular dependency issues.
    #
    # @example Simple list item
    #   item = ListItem.new(
    #     marker: "*",
    #     content: "Item text"
    #   )
    #
    # @example List item with nested list
    #   item = ListItem.new(
    #     marker: "*",
    #     content: "Parent item",
    #     nested_list: nested_list_block
    #   )
    class ListItem < Base
      # @!attribute marker
      #   @return [String, nil] the marker character(s) for this item
      #     (e.g., '*', '**', '.', '..', '-')
      attribute :marker, :string

      # @!attribute content
      #   @return [String, nil] text content of the list item
      attribute :content, :string

      # @!attribute nested_list
      #   @return [ListBlock, nil] nested list within this item
      #   Note: Typed as string initially, retyped after ListBlock defined
      attribute :nested_list, :string

      private

      # Attributes to compare for semantic equivalence
      #
      # List items are semantically equivalent if they have the same
      # content, nested list, and children, regardless of the specific
      # marker used.
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        %i[content nested_list children]
      end
    end

    # Represents a list block with proper nesting support
    #
    # Handles all AsciiDoc list types:
    # - Unordered lists (*, **, ***)
    # - Ordered lists (., .., ...)
    # - Description lists
    # - Labeled lists
    #
    # Lists can contain nested lists at multiple levels, with each level
    # tracked through marker_level.
    #
    # @example Creating an unordered list
    #   list = CoreModel::ListBlock.new(
    #     marker_type: "asterisk",
    #     marker_level: 1,
    #     items: [
    #       ListItem.new(marker: "*", content: "First item"),
    #       ListItem.new(marker: "*", content: "Second item")
    #     ]
    #   )
    #
    # @example Creating a nested list
    #   nested = CoreModel::ListBlock.new(
    #     marker_type: "asterisk",
    #     marker_level: 2,
    #     items: [ListItem.new(marker: "**", content: "Nested item")]
    #   )
    #   list = CoreModel::ListBlock.new(
    #     marker_type: "asterisk",
    #     marker_level: 1,
    #     items: [
    #       ListItem.new(
    #         marker: "*",
    #         content: "Parent item",
    #         nested_list: nested
    #       )
    #     ]
    #   )
    class ListBlock < Base
      # @!attribute marker_type
      #   @return [String, nil] type of list marker
      #     (e.g., 'asterisk', 'dash', 'numbered', 'labeled')
      attribute :marker_type, :string

      # @!attribute marker_level
      #   @return [Integer] nesting level of the list (default: 1)
      attribute :marker_level, :integer, default: -> { 1 }

      # @!attribute start
      #   @return [Integer, nil] starting number for ordered lists
      attribute :start, :integer

      # @!attribute items
      #   @return [Array<ListItem>] collection of list items
      attribute :items, ListItem, collection: true

      private

      # Attributes to compare for semantic equivalence
      #
      # Lists are semantically equivalent if they have the same marker
      # type and items, regardless of marker level (which is structural).
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        super + %i[marker_type items]
      end
    end

    # Re-open ListItem to properly type nested_list now that ListBlock
    # is defined
    class ListItem
      # Remove the temporary string-typed attribute
      remove_method :nested_list if method_defined?(:nested_list)
      remove_method :nested_list= if method_defined?(:nested_list=)

      # Re-define with proper ListBlock type
      attribute :nested_list, ListBlock
    end
  end
end
