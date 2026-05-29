# frozen_string_literal: true

require_relative 'base'

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
    end
  end
end
