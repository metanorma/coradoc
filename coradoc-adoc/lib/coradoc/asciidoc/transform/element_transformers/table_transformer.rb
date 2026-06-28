# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class TableTransformer
          class << self
            def transform_table(table)
              rows = Array(table.rows).map do |row|
                transform_table_row(row)
              end

              Coradoc::CoreModel::Table.new(
                id: table.id,
                title: table.title&.to_s,
                rows: rows,
                source_line: table.source_line
              )
            end

            def transform_table_row(row)
              cells = Array(row.columns).map do |cell|
                transform_table_cell(cell)
              end
              Coradoc::CoreModel::TableRow.new(
                cells: cells,
                header: row.header,
                source_line: row.source_line
              )
            end

            def transform_table_cell(cell)
              children = ToCoreModel.transform_inline_content(cell.content)

              Coradoc::CoreModel::TableCell.new(
                content: ToCoreModel.extract_text_content(cell.content),
                alignment: cell.horizontal_alignment,
                vertical_alignment: cell.vertical_alignment,
                colspan: cell.colspan,
                rowspan: cell.rowspan,
                style: cell.style_name,
                children: children,
                source_line: cell.source_line
              )
            end
          end
        end
      end
    end
  end
end
