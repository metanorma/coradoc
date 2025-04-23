# frozen_string_literal: true

module Coradoc
  module Model
    class CommentBlock < Base
      attribute :text, :string
      attribute :line_break, :string, default: -> { "\n" }

      asciidoc do
        map_attribute "text", to: :text
      end

      def to_asciidoc
        <<~ADOC.chomp
          ////
          #{text}
          ////#{line_break}
        ADOC
      end
    end
  end
end
