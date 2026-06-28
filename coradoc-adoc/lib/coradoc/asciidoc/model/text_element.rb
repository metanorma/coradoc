# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Single source of truth for the markers AsciiDoc uses to terminate
      # a TextElement. Exposed as a module so the transformer can compare
      # against the constant without hand-writing string literals across
      # the codebase (DRY), and so future markers (e.g. a hypothetical
      # backslash-style hard break) extend one place.
      module LineBreakMarker
        HARD = '+'
      end
      private_constant :LineBreakMarker

      class TextElement < Base
        def inline?
          true
        end

        attribute :id, :string
        attribute :content,
                  Lutaml::Model::Serializable,
                  default: -> { '' },
                  polymorphic: [
                    Lutaml::Model::Type::String,
                    :array
                  ]
        attribute :line_break, :string, default: -> { '' }

        # Semantic predicates over the line-break marker. Consumers (the
        # transformer, the serializer) call these instead of comparing
        # line_break against literal strings, so the wire format for
        # hard breaks is owned by the model layer (SRP).
        def hard_break?
          line_break == LineBreakMarker::HARD
        end

        def soft_break?
          line_break.to_s.empty?
        end

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
