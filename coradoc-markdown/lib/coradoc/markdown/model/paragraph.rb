# frozen_string_literal: true

module Coradoc
  module Markdown
    # Paragraph model representing a Markdown paragraph.
    #
    # @example Create a paragraph
    #   para = Coradoc::Markdown::Paragraph.new(text: "Hello World")
    #
    class Paragraph < Base
      attribute :text, :string

      # Mixed content (strings and inline model objects)
      # @return [Array] mixed content array
      attr_reader :children

      def initialize(text: '', children: nil)
        super()
        @text = text
        @children = children || []
      end

      def children=(value)
        @children = value || []
      end
    end
  end
end
