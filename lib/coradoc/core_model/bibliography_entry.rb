# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Individual bibliography entry (reference).
    #
    # Bibliography entries represent single references within a bibliography,
    # with anchor names for citation linking.
    #
    # @!attribute [r] anchor_name
    #   @return [String, nil] The anchor name for citing this entry (e.g., "ISO712")
    #
    # @!attribute [r] document_id
    #   @return [String, nil] The document identifier (e.g., "ISO 712")
    #
    # @!attribute [r] ref_text
    #   @return [String, nil] The reference text/citation description
    #
    # @!attribute [r] url
    #   @return [String, nil] Optional URL for the reference
    #
    # @example Create a bibliography entry
    #   entry = Coradoc::CoreModel::BibliographyEntry.new(
    #     anchor_name: "ISO712",
    #     document_id: "ISO 712",
    #     ref_text: "Cereals and cereal products. Determination of moisture content."
    #   )
    #
    class BibliographyEntry < Base
      attribute :anchor_name, :string
      attribute :document_id, :string
      attribute :ref_text, :string
      attribute :url, :string
    end
  end
end
