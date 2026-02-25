# frozen_string_literal: true

module Coradoc
  module Markdown
    # CodeBlock model representing a fenced code block.
    #
    # @example Create a code block
    #   code = Coradoc::Markdown::CodeBlock.new(
    #     language: "ruby",
    #     code: "puts 'Hello World'"
    #   )
    #
    class CodeBlock < Base
      attribute :language, :string
      attribute :code, :string

      def initialize(language: nil, code: '')
        super()
        @language = language
        @code = code
      end
    end
  end
end
