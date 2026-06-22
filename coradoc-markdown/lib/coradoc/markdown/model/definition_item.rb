# frozen_string_literal: true

module Coradoc
  module Markdown
    # DefinitionItem model representing a single definition in a definition list.
    #
    # Each definition item contains the definition content and can have
    # nested blocks (paragraphs, code blocks, lists, etc.)
    #
    # @example Simple definition
    #   defn = Coradoc::Markdown::DefinitionItem.new(content: "A Markdown parser")
    #
    class DefinitionItem < Base
      # The definition content (text or nested blocks)
      attribute :content, :string

      # Inline content can be an array of text/inline elements
      attribute :inline_content, :string, collection: true

      # Nested block content (paragraphs, code blocks, lists, etc.)
      attribute :blocks, :string, collection: true

      # Mixed inline content (strings and inline model objects) carried
      # from the CoreModel definition_children so serializers can render
      # backtick code spans, bold, italics, etc.
      attr_reader :children

      def initialize(args = {})
        super()
        @content = args[:content]
        @inline_content = args.fetch(:inline_content, [])
        @blocks = args.fetch(:blocks, [])
        @children = args.fetch(:children, [])
      end

      def children=(value)
        @children = value || []
      end
    end
  end
end
