# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Paragraph block element.
      #
      # Represents a paragraph of text in an AsciiDoc document. Paragraphs can
      # contain mixed content including text, inline formatting, and other elements.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the paragraph
      # @!attribute [r] content
      #   @return [Array<String, TextElement>] Paragraph content (can be text or TextElement objects)
      # @!attribute [r] title
      #   @return [String, nil] Optional title for the paragraph
      # @!attribute [r] attributes
      #   @return [AttributeList] Additional paragraph attributes (style, position, etc.)
      # @!attribute [r] tdsinglepara
      #   @return [Boolean] Special table cell paragraph flag
      #
      # @example Create a simple paragraph
      #   para = Coradoc::AsciiDoc::Model::Paragraph.new("Hello World")
      #   para.to_adoc # => "Hello World"
      #
      # @example Create a paragraph with attributes
      #   para = Coradoc::AsciiDoc::Model::Paragraph.new(
      #     "Note: This is important",
      #     attributes: Coradoc::AsciiDoc::Model::Coradoc::AsciiDoc::Model::AttributeList.new(["NOTE"])
      #   )
      #
      class Paragraph < Attached
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        # NOTE: Content uses polymorphic collection supporting both String and TextElement
        # types via lutaml-model's polymorphic attribute feature.
        attribute :content,
                  Lutaml::Model::Serializable,
                  collection: true,
                  initialize_empty: true,
                  polymorphic: [
                    # :string,
                    Lutaml::Model::Type::String,
                    Coradoc::AsciiDoc::Model::TextElement
                  ]
        attribute :title, :string
        attribute :attributes, Coradoc::AsciiDoc::Model::AttributeList, default: lambda {
          Coradoc::AsciiDoc::Model::AttributeList.new
        }
        attribute :tdsinglepara, :boolean, default: -> { false }
        # Trailing newlines after paragraph for exact round-trip preservation
        # nil = use default "\n\n" spacing (semantic mode)
        # string = exact trailing newlines from original (exact mode)
        attribute :trailing_newlines, :string, default: nil
      end
    end
  end
end
