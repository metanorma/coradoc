# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Title element for sections and document headers.
      #
      # Represents a title with optional level information. Titles are used by
      # sections to define their heading level and text content.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the title
      # @!attribute [r] content
      #   @return [Array<TextElement>] Title text content (can include inline formatting)
      # @!attribute [r] level_int
      #   @return [Integer, nil] Heading level (0-5 for standard, 6+ uses style attribute)
      # @!attribute [r] line_break
      #   @return [String] Line break character after title (default: newline)
      # @!attribute [r] style
      #   @return [String, nil] Optional style attribute for title formatting
      #
      # @example Create a level 1 title
      #   title = Coradoc::AsciiDoc::Model::Title.new(
      #     content: [Coradoc::AsciiDoc::Model::TextElement.new("Chapter 1")],
      #     level_int: 0
      #   )
      #   title.to_adoc # => "= Chapter 1\n"
      #
      # @example Create a level 2 title
      #   title = Coradoc::AsciiDoc::Model::Title.new(
      #     content: [Coradoc::AsciiDoc::Model::TextElement.new("Section 1.1")],
      #     level_int: 1
      #   )
      #   title.to_adoc # => "== Section 1.1\n"
      #
      class Title < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :content, Coradoc::AsciiDoc::Model::TextElement, collection: true
        # attribute :level, :string
        attribute :level_int, :integer
        attribute :line_break, :string, default: -> { "\n" }
        attribute :style, :string

        alias text content

        # Convert title content to string
        # @return [String] The title text
        def to_s
          case content
          when String
            content
          when Array
            content.map do |item|
              item.is_a?(Coradoc::AsciiDoc::Model::TextElement) ? item.content.to_s : item.to_s
            end.join
          else
            content.to_s
          end
        end

        def level_str
          return '' if level_int.nil?

          if level_int <= 5
            '=' * (level_int + 1)
          else
            '======'
          end
        end

        def style_str
          return '' if level_int.nil?

          _style = [style]
          _style << "level=#{level_int}" if level_int > 5
          _style = _style.compact.join(',')

          _style.empty? ? '' : "[#{_style}]\n"
        end
      end
    end
  end
end
