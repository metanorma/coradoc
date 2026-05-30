# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class BibliographyEntryDrop < Base
        def anchor_name
          n = @model.anchor_name
          n && !n.to_s.empty? ? n : nil
        end

        def document_id
          optional_text(@model.document_id)
        end

        def ref_text
          optional_text(@model.ref_text)
        end
      end

      DropFactory.register(CoreModel::BibliographyEntry, BibliographyEntryDrop)
    end
  end
end
