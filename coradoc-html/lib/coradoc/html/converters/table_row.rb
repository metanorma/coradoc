# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class TableRow < Base
        def self.to_html(row, _options = {})
          return '' unless row

          cells = row.cells || []
          cells_html = cells.map do |cell|
            TableCell.to_html(cell)
          end.join("\n")

          attrs = {}
          attrs[:id] = row.id if row.id

          NodeBuilder.build(:tr, cells_html, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'tr'

          cells = element.css('td, th').map do |cell_elem|
            TableCell.to_coradoc(cell_elem)
          end.compact

          Coradoc::CoreModel::TableRow.new(cells: cells)
        end
      end
    end
  end
end
