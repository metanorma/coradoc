# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class TableCellDrop < Base
        def header?
          @model.header == true
        end

        def html_tag
          TagMapping.tag_for(header? ? :table_header : :table_cell)
        end

        def colspan
          @model.colspan&.to_s
        end

        def rowspan
          @model.rowspan&.to_s
        end

        def style
          "text-align: #{@model.alignment}" if @model.alignment
        end

        def content
          content_to_liquid(@model.renderable_content)
        end
      end

      DropFactory.register(CoreModel::TableCell, TableCellDrop)
    end
  end
end
