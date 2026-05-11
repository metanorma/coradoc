# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a footnote definition in a document
    #
    # Footnotes are used for auxiliary information, citations, or
    # explanatory notes that appear at the bottom of a page or
    # end of a document.
    #
    # @example Creating a simple footnote
    #   footnote = CoreModel::Footnote.new(
    #     id: "fn1",
    #     content: "This is a footnote explanation."
    #   )
    #
    # @example Creating a footnote with backlink
    #   footnote = CoreModel::Footnote.new(
    #     id: "cite1",
    #     content: "Smith, J. (2024). The Reference.",
    #     backlink: true
    #   )
    class Footnote < Base
      # @!attribute id
      #   @return [String, nil] the footnote identifier (e.g., "1", "fn1")
      attribute :id, :string

      # @!attribute content
      #   @return [String, nil] the footnote content
      attribute :content, :string

      # @!attribute inline_content
      #   @return [Array<String>, nil] inline content elements
      attribute :inline_content, :string, collection: true

      # @!attribute backlink
      #   @return [Boolean] whether to include backlink to reference
      attribute :backlink, :boolean, default: -> { true }

      private

      def comparable_attributes
        super + %i[id content backlink]
      end
    end

    # Represents an inline footnote reference
    #
    # FootnoteReference links to a Footnote definition within document text.
    #
    # @example Creating a footnote reference
    #   ref = CoreModel::FootnoteReference.new(id: "fn1")
    #   # Renders as: [^fn1] in Markdown, <sup>1</sup> in HTML
    class FootnoteReference < Base
      # @!attribute id
      #   @return [String, nil] the footnote identifier being referenced
      attribute :id, :string

      private

      def comparable_attributes
        super + %i[id]
      end
    end

    # Represents an abbreviation definition in a document
    #
    # Abbreviations define the expansion of shortened terms.
    # They are typically rendered with the full definition on first use.
    #
    # @example Creating an abbreviation
    #   abbr = CoreModel::Abbreviation.new(
    #     term: "API",
    #     definition: "Application Programming Interface"
    #   )
    class Abbreviation < Base
      # @!attribute term
      #   @return [String, nil] the abbreviated term
      attribute :term, :string

      # @!attribute definition
      #   @return [String, nil] the full definition/expansion
      attribute :definition, :string

      private

      def comparable_attributes
        super + %i[term definition]
      end
    end
  end
end
