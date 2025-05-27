# frozen_string_literal: true

module Coradoc
  module Model
    class TextElement < Base
      attribute :id, :string
      attribute :content, :string, default: -> { "" }
      attribute :line_break, :string, default: -> { "" }
      attribute :html_cleanup, :boolean, default: -> { false }

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "line_break", to: :line_break
      end

      # TODO: missing many methods from Coradoc::Element::TextElement
      def to_asciidoc
        Coradoc::Generator.gen_adoc(content) + line_break
      end

      def self.escape_keychars(string)
        subs = { "*" => '\*', "_" => '\_' }
        string
          .gsub(/((?<=\s)[\*_]+)|[\*_]+(?=\s)/) do |n|
          n.chars.map { |char|
            subs[char]
          }.join
        end
      end
    end
  end
end
