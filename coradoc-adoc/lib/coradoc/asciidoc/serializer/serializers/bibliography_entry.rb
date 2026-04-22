# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class BibliographyEntry < Base
          def to_adoc(model, _options = {})
            text = serialize_children(model.ref_text) if model.ref_text
            adoc = "* [[[#{model.anchor_name}"
            adoc << ",#{model.document_id}" if model.document_id
            adoc << ']]]'
            adoc << text.to_s if model.ref_text
            adoc << (model.line_break || "\n")
            adoc
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::BibliographyEntry, Serializers::BibliographyEntry)
    end
  end
end
