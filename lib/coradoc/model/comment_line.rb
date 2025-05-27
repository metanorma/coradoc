# frozen_string_literal: true

module Coradoc
  module Model
    class CommentLine < Base
      attribute :text, :string
      attribute :line_break, :string, default: -> { "\n" }

      asciidoc do
        map_attribute "text", to: :text
      end

      def to_asciidoc
        "// #{text}#{line_break}"
      end
    end
  end
end
