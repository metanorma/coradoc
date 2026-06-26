# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class BiblioEntry < Base
        registers 'biblio_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::BibliographyEntry.new(
            anchor_name: attrs&.anchor_name,
            document_id: attrs&.document_id,
            ref_text: extract_text(node)
          )
        end
      end
    end
  end
end
