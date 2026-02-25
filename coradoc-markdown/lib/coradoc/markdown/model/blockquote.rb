# frozen_string_literal: true

module Coradoc
  module Markdown
    # Blockquote model representing a Markdown blockquote (> prefix).
    #
    # @example Create a blockquote
    #   quote = Coradoc::Markdown::Blockquote.new(
    #     content: "This is a quoted text."
    #   )
    #
    class Blockquote < Base
      attribute :content, :string

      def initialize(content: '')
        super()
        @content = content
      end
    end
  end
end
