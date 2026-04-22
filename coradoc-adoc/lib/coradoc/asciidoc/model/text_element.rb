# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class TextElement < Base
        attribute :id, :string
        attribute :content,
                  Lutaml::Model::Serializable,
                  default: -> { '' },
                  polymorphic: [
                    Lutaml::Model::Type::String,
                    :array
                  ]
        attribute :line_break, :string, default: -> { '' }

        def self.escape_keychars(string)
          subs = { '*' => '\*', '_' => '\_' }
          string
            .gsub(/((?<=\s)[*_]+)|[*_]+(?=\s)/) do |n|
            n.chars.map do |char|
              subs[char]
            end.join
          end
        end

        # Get text content as string
        #
        # @return [String] The text content
        #
        def to_s
          case content
          when String
            content
          when Array
            content.map(&:to_s).join
          when Lutaml::Model::Serializable
            # Handle Lutaml models - try to extract text properly
            if content.respond_to?(:to_adoc)
              content.to_adoc
            elsif content.respond_to?(:text)
              content.text.to_s
            elsif content.respond_to?(:content)
              content.content.to_s
            else
              ''
            end
          when nil
            ''
          else
            # Only use to_s for simple types that respond to to_str
            content.respond_to?(:to_str) ? content.to_s : ''
          end
        end

        # Alias for text to work with ContentList
        #
        # @return [String] The text content
        #
        def text
          to_s
        end
      end
    end
  end
end
