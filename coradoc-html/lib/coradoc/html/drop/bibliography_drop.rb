# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class BibliographyDrop < Base
        def entries
          children_to_liquid(@model.entries)
        end
      end

      DropFactory.register(CoreModel::Bibliography, BibliographyDrop)
    end
  end
end
