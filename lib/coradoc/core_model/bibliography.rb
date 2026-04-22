# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Bibliography section in a document.
    #
    # Bibliography sections contain lists of references cited in the document.
    # They are typically marked with [bibliography] attribute in AsciiDoc.
    #
    # @!attribute [r] id
    #   @return [String, nil] Optional identifier for the bibliography
    #
    # @!attribute [r] title
    #   @return [String, nil] Bibliography section title
    #
    # @!attribute [r] level
    #   @return [Integer, nil] Section level
    #
    # @!attribute [r] entries
    #   @return [Array<Coradoc::CoreModel::BibliographyEntry>] Bibliography entries
    #
    # @example Create a bibliography section
    #   bib = Coradoc::CoreModel::Bibliography.new(
    #     id: "norm-refs",
    #     title: "Normative references",
    #     entries: [
    #       Coradoc::CoreModel::BibliographyEntry.new(
    #         anchor_name: "ISO712",
    #         document_id: "ISO 712",
    #         ref_text: "Cereals and cereal products..."
    #       )
    #     ]
    #   )
    #
    class Bibliography < Base
      attribute :id, :string
      attribute :title, :string
      attribute :level, :integer
      attribute :entries, Coradoc::CoreModel::BibliographyEntry, collection: true
    end
  end
end
