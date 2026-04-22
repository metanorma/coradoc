# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Bibliography block element for AsciiDoc documents.
      #
      # Bibliographies contain lists of bibliography entries (references)
      # with support for various citation styles.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the bibliography
      #
      # @!attribute [r] title
      #   @return [String, nil] Optional bibliography title
      #
      # @!attribute [r] entries
      #   @return [Array<Coradoc::AsciiDoc::Model::BibliographyEntry>] Bibliography entry items
      #
      # @example Create a bibliography
      #   bib = Coradoc::AsciiDoc::Model::Bibliography.new
      #   bib.title = "References"
      #   entry = Coradoc::AsciiDoc::Model::BibliographyEntry.new
      #   bib.entries << entry
      #
      # @see Coradoc::AsciiDoc::Model::BibliographyEntry Individual bibliography entries
      #
      class Bibliography < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :title, :string
        attribute :entries, Coradoc::AsciiDoc::Model::BibliographyEntry, collection: true
      end
    end
  end
end
