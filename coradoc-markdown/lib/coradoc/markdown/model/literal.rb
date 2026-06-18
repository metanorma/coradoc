# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Literal block — preformatted text with no syntax highlighting and
    # no inline formatting. Distinct from a code block (which carries a
    # language for highlighting).
    #
    # Markdown: indented code block (4 leading spaces per line).
    class Literal < Base
      attribute :content, :string

      def initialize(content:, **rest)
        super
        @content = content
      end
    end
  end
end
