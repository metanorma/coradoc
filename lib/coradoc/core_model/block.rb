# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Generic delimited block model
    #
    # Represents all standard AsciiDoc delimited blocks including:
    # - Example blocks (====)
    # - Literal blocks (````)
    # - Listing blocks (----)
    # - Open blocks (--)
    # - Pass blocks (++++/++++)
    # - Quote blocks (____)
    # - Sidebar blocks (****)
    # - Source blocks (----)
    # - Paragraphs (element_type: 'paragraph')
    #
    # This is a schema-agnostic representation that captures the semantic
    # structure without schema-specific interpretation.
    #
    # @example Creating a generic block
    #   block = CoreModel::Block.new(
    #     delimiter_type: "====",
    #     delimiter_length: 4,
    #     content: "Example content here"
    #   )
    #
    # @example Creating a source block
    #   block = CoreModel::Block.new(
    #     delimiter_type: "----",
    #     content: "puts 'Hello, World!'",
    #     attributes: [{ role: "source", language: "ruby" }]
    #   )
    #
    # @example Creating a paragraph with inline formatting
    #   block = CoreModel::Block.new(
    #     element_type: "paragraph",
    #     children: [
    #       "Text with ",
    #       CoreModel::InlineElement.new(format_type: "bold", content: "bold"),
    #       " text"
    #     ]
    #   )
    class Block < Base
      # @!attribute element_type
      #   @return [String, nil] the semantic type of the block
      #     (e.g., 'paragraph', 'block')
      attribute :element_type, :string

      # @!attribute delimiter_type
      #   @return [String, nil] the delimiter character(s) used
      #     (e.g., '****', '====', '----')
      attribute :delimiter_type, :string

      # @!attribute delimiter_length
      #   @return [Integer] number of delimiter characters (default: 4)
      attribute :delimiter_length, :integer, default: -> { 4 }

      # @!attribute content
      #   @return [String, nil] the block's text content (simple string)
      #     For mixed content with inline elements, use children instead.
      attribute :content, :string

      # @!attribute lines
      #   @return [Array<String>, nil] individual lines of content
      attribute :lines, :string, collection: true

      # @!attribute language
      #   @return [String, nil] language identifier for source code blocks
      attribute :language, :string

      # Mixed content (strings and InlineElement objects)
      # @return [Array] mixed content array
      attr_reader :children

      # Initialize block with optional children support
      # @param args [Hash] initialization arguments
      def initialize(args = {})
        @children = args.delete(:children) || []
        super(args)
      end

      # Set children array
      # @param value [Array] mixed content array
      def children=(value)
        @children = value || []
      end

      # Get content for rendering, preferring children over content
      # When children are all plain strings, use the content attribute instead
      # since it already has proper spacing between lines.
      # @return [Array, String, nil] content to render
      def renderable_content
        return content if children.nil? || children.none?
        return content if content && children.all?(String)

        children
      end

      # Override to include raw Ruby children attribute in hash output
      def to_hash
        super.tap do |h|
          h['children'] = serialize_children(children) if children&.any?
        end
      end

      private

      # Attributes to compare for semantic equivalence
      #
      # Blocks are semantically equivalent if they have the same
      # delimiter type and content, regardless of delimiter length
      # or line structure.
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        super + %i[delimiter_type content]
      end
    end
  end
end
