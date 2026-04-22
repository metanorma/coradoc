# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # List item element for ordered and unordered AsciiDoc lists.
        #
        # Represents a single item in an ordered or unordered list, which can
        # contain text content, attached blocks (paragraphs, admonitions),
        # and nested lists.
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the list item
        #
        # @!attribute [r] content
        #   @return [Array<Coradoc::AsciiDoc::Model::Base>] Polymorphic content
        #
        # @!attribute [r] marker
        #   @return [String, nil] Custom list marker for this item
        #
        # @!attribute [r] subitem
        #   @return [String, nil] Sub-item text
        #
        # @!attribute [r] line_break
        #   @return [String] Line break character (default: "\n")
        #
        # @!attribute [r] attached
        #   @return [Array<Coradoc::AsciiDoc::Model::Attached>] Attached blocks
        #
        # @!attribute [r] nested
        #   @return [Coradoc::AsciiDoc::Model::List::Nestable, nil] Nested list
        #
        # @example Create a simple list item
        #   item = Coradoc::AsciiDoc::Model::List::Item.new
        #   item.content = [Coradoc::AsciiDoc::Model::TextElement.new("First item")]
        #
        # @example Create a list item with nested list
        #   item = Coradoc::AsciiDoc::Model::List::Item.new
        #   item.nested = Coradoc::AsciiDoc::Model::List::Unordered.new
        #   item.nested.items << Coradoc::AsciiDoc::Model::List::Item.new
        #
        class Item < Base
          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :content,
                    Coradoc::AsciiDoc::Model::Base,
                    polymorphic: [
                      Coradoc::AsciiDoc::Model::TextElement,
                      Coradoc::AsciiDoc::Model::Section
                    ]
          attribute :marker, :string
          attribute :subitem, :string
          attribute :line_break, :string, default: -> { "\n" }

          attribute :attached,
                    Coradoc::AsciiDoc::Model::Attached,
                    polymorphic: [
                      Coradoc::AsciiDoc::Model::Admonition,
                      Coradoc::AsciiDoc::Model::Paragraph,
                      Coradoc::AsciiDoc::Model::Block::Core
                    ],
                    collection: true,
                    initialize_empty: true

          attribute :nested, Coradoc::AsciiDoc::Model::List::Nestable

          HARDBREAK_MARKERS = %i[hardbreak init].freeze
          STRIP_UNICODE_BEGIN_MARKERS = (HARDBREAK_MARKERS.dup + [false]).freeze
          STRIP_UNICODE_END_MARKERS = [:hardbreak, :end, false].freeze

          def inline?(elem)
            case elem
            when Inline::HardLineBreak
              :hardbreak
            when ->(i) { i.class.name.to_s.include? '::Inline::' }
              true
            when String, TextElement, Image::InlineImage
              true
            else
              false
            end
          end
        end
      end
    end
  end
end
