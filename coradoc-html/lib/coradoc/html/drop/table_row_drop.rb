# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class TableRowDrop < Base
        def header?
          @model.header == true
        end

        def html_tag
          'tr'
        end

        def cells
          children_to_liquid(@model.cells)
        end
      end

      DropFactory.register(CoreModel::TableRow, TableRowDrop)
    end
  end
end
