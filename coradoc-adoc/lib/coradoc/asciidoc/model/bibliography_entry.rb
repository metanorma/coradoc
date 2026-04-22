# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Individual bibliography entry for AsciiDoc documents.
      #
      # Bibliography entries represent single references within a bibliography,
      # with anchor names for citation linking.
      #
      # @!attribute [r] anchor_name
      #   @return [String, nil] The anchor name for citing this entry
      #
      # @!attribute [r] document_id
      #   @return [String, nil] The document identifier
      #
      # @!attribute [r] ref_text
      #   @return [String, nil] The reference text/citation
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "")
      #
      # @example Create a bibliography entry
      #   entry = Coradoc::AsciiDoc::Model::BibliographyEntry.new
      #   entry.anchor_name = "smith2023"
      #   entry.ref_text = "Smith, J. (2023). Example citation."
      #
      # @see Coradoc::AsciiDoc::Model::Bibliography Bibliography container
      #
      class BibliographyEntry < Base
        attribute :anchor_name, :string
        attribute :document_id, :string
        attribute :ref_text, :string
        attribute :line_break, :string, default: -> { '' }
      end
    end
  end
end
