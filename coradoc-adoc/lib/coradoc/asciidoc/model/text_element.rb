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
          when Coradoc::AsciiDoc::Model::Base
            content.to_adoc
          when Lutaml::Model::Serializable
            if content.class.attributes.key?(:content)
              content.content.to_s
            else
              ''
            end
          when nil
            ''
          else
            content.is_a?(String) ? content.to_s : ''
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
