# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Table < ElementSerializer
          handles_type ::Coradoc::Markdown::Table

          def call(element, _ctx)
            cols = [element.headers.size, *element.rows.map { |r| row_cells(r).size }].max
            return '' if cols.zero?

            headers = element.headers.empty? ? Array.new(cols, '') : element.headers
            header_row = "| #{headers.join(' | ')} |"
            separator = "| #{headers.map { '---' }.join(' | ')} |"
            rows = element.rows.map do |row|
              cells = row_cells(row).fill('', row_cells(row).size...cols)
              "| #{cells.join(' | ')} |"
            end

            [header_row, separator, *rows].join("\n")
          end

          private

          # Rows are stored as either Array<String> (cells) or pipe-joined String
          def row_cells(row)
            row.is_a?(Array) ? row : row.to_s.split(' | ')
          end
        end
      end
    end
  end
end
