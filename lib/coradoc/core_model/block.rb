# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Semantic block type constants
    #
    # Format gems own the mapping between their syntax and these
    # canonical semantic types. The core model never stores raw
    # delimiter strings.
    module BlockSemanticType
      SOURCE_CODE = :source_code
      LISTING = :listing
      EXAMPLE = :example
      QUOTE = :quote
      SIDEBAR = :sidebar
      LITERAL = :literal
      OPEN = :open
      PASS = :pass
      VERSE = :verse
      HORIZONTAL_RULE = :horizontal_rule
      COMMENT = :comment
      PARAGRAPH = :paragraph
      VIDEO = :video
      AUDIO = :audio
      ANNOTATION = :annotation
      REVIEWER = :reviewer

      def self.all
          [SOURCE_CODE, LISTING, EXAMPLE, QUOTE, SIDEBAR, LITERAL, OPEN, PASS,
           VERSE, HORIZONTAL_RULE, COMMENT, PARAGRAPH, VIDEO, AUDIO,
           ANNOTATION, REVIEWER].freeze
        end
    end

    # Generic block model
    #
    # Represents all block-level elements in a format-neutral way.
    # Each block has a `block_semantic_type` symbol (e.g., :source_code,
    # :quote, :example) that captures its semantic meaning without
    # tying it to any specific format's syntax.
    #
    # @example Creating a source code block
    #   block = CoreModel::Block.new(
    #     block_semantic_type: :source_code,
    #     content: "puts 'Hello, World!'",
    #     language: "ruby"
    #   )
    #
    # @example Creating a paragraph with inline formatting
    #   block = CoreModel::Block.new(
    #     block_semantic_type: :paragraph,
    #     children: [
    #       "Text with ",
    #       CoreModel::InlineElement.new(format_type: "bold", content: "bold"),
    #       " text"
    #     ]
    #   )
    class Block < Base
      include ChildrenContent

      class << self
        # Class-level semantic type — overridden by each typed subclass.
        # Returns nil for the generic Block base class.
        def semantic_type
          nil
        end
      end

      # Resolve the semantic type from this block instance.
      # Checks class-level semantic_type first (typed subclasses),
      # then the block_semantic_type attribute, then element_type,
      # then delimiter_type fallback.
      def resolve_semantic_type
        self.class.semantic_type ||
          (block_semantic_type&.to_sym) ||
          resolve_semantic_from_element_type ||
          resolve_semantic_from_delimiter
      end

      # @!attribute block_semantic_type
      #   @return [String, nil] the semantic type of the block
      #     (e.g., 'source_code', 'quote', 'example', 'paragraph')
      attribute :block_semantic_type, :string

      # @!attribute element_type
      #   @return [String, nil] the structural role of the block
      #     (e.g., 'paragraph', 'block')
      attribute :element_type, :string

      # @!attribute delimiter_type
      #   @return [String, nil] DEPRECATED — use block_semantic_type.
      #     Retained for backward compatibility during migration.
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
      # @return [Array] mixed content array (via ChildrenContent)

      private

      def resolve_semantic_from_element_type
        case element_type
        when 'paragraph' then :paragraph
        when 'comment' then :comment
        else nil
        end
      end

      def resolve_semantic_from_delimiter
        delim = delimiter_type
        return nil unless delim && delim.length >= 4

        char = delim[0]
        DELIMITER_CHAR_TO_SEMANTIC[char] || nil
      end

      # Map delimiter first character to semantic type (backward compat)
      DELIMITER_CHAR_TO_SEMANTIC = {
        '-' => :source_code,
        '=' => :example,
        '_' => :quote,
        '*' => :sidebar,
        '.' => :literal,
        '+' => :pass
      }.freeze

      # Attributes to compare for semantic equivalence
      #
      # @return [Array<Symbol>] list of comparable attributes
      def comparable_attributes
        super + %i[block_semantic_type content]
      end
    end
  end
end
