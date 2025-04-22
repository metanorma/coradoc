# frozen_string_literal: true

module Coradoc
  module Model
    class TextElement < Base
      attribute :id, :string
      attribute :content, :string, default: -> { "" }
      attribute :line_break, :string, default: -> { "" }

      asciidoc do
        map_content to: :content
      end

      def to_asciidoc
        Coradoc::Generator.gen_adoc(content) + line_break
      end
    end
  end
end
