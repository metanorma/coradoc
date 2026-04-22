# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class TableRow < Base
        # Convert CoreModel::TableRow to HTML <tr>
        def self.to_html(row, _options = {})
          return '' unless row

          # CoreModel::TableRow uses cells
          cells = row.respond_to?(:cells) ? row.cells : []
          columns_html = cells.map do |cell|
            TableCell.to_html(cell)
          end.join("\n")

          attrs = build_attributes(row)

          "<tr#{attrs}>\n#{columns_html}\n</tr>"
        end

        # Convert HTML <tr> to CoreModel::TableRow
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'tr'

          # Get all cells (both td and th)
          cells = element.css('td, th').map do |cell_elem|
            TableCell.to_coradoc(cell_elem)
          end.compact

          Coradoc::CoreModel::TableRow.new(cells: cells)
        end

        def self.build_attributes(row)
          attrs = []

          # Add ID if present
          attrs << %( id="#{escape_attribute(row.id)}") if row.respond_to?(:id) && row.id

          attrs.join
        end
      end
    end
  end
end
