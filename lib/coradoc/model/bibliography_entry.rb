# frozen_string_literal: true

module Coradoc
  module Model
    class BibliographyEntry < Base
      attribute :anchor_name, :string
      attribute :document_id, :string
      attribute :ref_text, :string
      attribute :line_break, :string, default: -> { "" }

      asciidoc do
        map_model to: Coradoc::Element::BibliographyEntry
        map_attribute "anchor_name", to: :anchor_name
        map_attribute "document_id", to: :document_id
        map_attribute "ref_text", to: :ref_text
        map_attribute "line_break", to: :line_break
      end

      def to_asciidoc
        text = Coradoc::Generator.gen_adoc(ref_text) if ref_text
        adoc = "* [[[#{anchor_name}"
        adoc << ",#{document_id}" if document_id
        adoc << "]]]"
        adoc << text.to_s if ref_text
        adoc << line_break
        adoc
      end
    end
  end
end
