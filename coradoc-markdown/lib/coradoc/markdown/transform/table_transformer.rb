# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module TableTransformer
        class << self
          def transform_table(table)
            headers = []
            rows = []

            table_rows = Array(table.rows)
            if table_rows.any?
              first_row = table_rows.first
              first_row_cells = Array(first_row&.cells)

              # Check if first row has header cells
              if first_row_cells.any?(&:header)
                headers = first_row_cells.map(&:flat_text)
                table_rows = table_rows[1..] || []
              end

              # Convert remaining rows to pipe-separated strings
              rows = table_rows.map do |row|
                Array(row.cells).map(&:flat_text).join(' | ')
              end
            end

            Coradoc::Markdown::Table.new(
              headers: headers,
              rows: rows
            )
          end
        end

        FromCoreModel.register(CoreModel::Table, method(:transform_table))
      end
    end
  end
end
