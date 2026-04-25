# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Represents highlighted text using == syntax (extended Markdown).
    #
    # Example: ==highlighted text==
    #
    class Highlight < Base
      attribute :text, :string

      def to_md
        "==#{text}=="
      end
    end
  end
end
