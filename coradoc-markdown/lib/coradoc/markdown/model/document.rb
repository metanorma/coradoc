# frozen_string_literal: true

module Coradoc
  module Markdown
    # Document model representing a Markdown document.
    #
    # The Document class is the main container for parsed Markdown content.
    # It holds the document's blocks (headings, paragraphs, lists, etc.).
    #
    # @example Create a new document
    #   doc = Coradoc::Markdown::Document.new(
    #     blocks: [
    #       Coradoc::Markdown::Heading.new(level: 1, text: "My Document"),
    #       Coradoc::Markdown::Paragraph.new(text: "Hello World")
    #     ]
    #   )
    #
    class Document < Base
      attribute :blocks, Coradoc::Markdown::Base, collection: true

      # @param [Integer] index The index of the block to retrieve
      # @return [Coradoc::Markdown::Base] The block at the specified index
      def [](index)
        blocks[index]
      end

      # @param [Integer] index The index of the block to set
      # @param [Coradoc::Markdown::Base] value The block to set
      def []=(index, value)
        blocks[index] = value
      end

      # Create a document from an array of blocks
      def self.from_ast(elements)
        new(blocks: elements)
      end
    end
  end
end
