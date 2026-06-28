# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Pure functions for table row/column layout.
      #
      # Extracted from the Transformer god class so that:
      # - the Transformer stays focused on rule wiring
      # - the layout math can be unit-tested in isolation
      # - future formats (Markdown tables, DOCX) can reuse the math
      #   without reaching into AsciiDoc::Transformer
      module TableLayout
        module_function

        # Parse the `cols=` attribute to determine column count.
        # @param attrs [Model::AttributeList, Hash, nil]
        # @return [Integer, nil]
        def parse_cols_attribute(attrs)
          return nil if attrs.nil?

          cols_value = if attrs.is_a?(Model::AttributeList)
                         attrs.named.find { |n| n.name.to_s == 'cols' }&.value
                       elsif attrs.is_a?(Hash)
                         attrs['cols'] || attrs[:cols]
                       end

          return nil if cols_value.nil?

          cols_str = cols_value.is_a?(Array) ? cols_value.first.to_s : cols_value.to_s
          cols_str = cols_str.gsub(/^["']|["']$/, '')

          return Regexp.last_match(1).to_i if cols_str =~ /^(\d+)\*$/
          return cols_str.split(',').size if cols_str.include?(',')

          cols_str.to_i if /^\d+$/.match?(cols_str)
        end

        # Group a flat list of cells into rows of `col_count` slots.
        # @param cells [Array<Model::TableCell, Hash, Object>]
        # @param explicit_col_count [Integer, nil]
        # @return [Array<Model::TableRow>]
        def group_cells_into_rows(cells, explicit_col_count = nil)
          return [] if cells.nil? || cells.empty?

          normalized_cells = cells.map { |cell| TableCellBuilder.normalize_cell(cell) }

          col_count = explicit_col_count
          col_count = infer_column_count(normalized_cells) if col_count.nil? || col_count.zero?
          col_count = normalized_cells.size if col_count.nil? || col_count.zero?

          rows = []
          current_row = []
          current_slots = 0

          normalized_cells.each do |cell|
            colspan = cell.is_a?(Model::TableCell) && cell.colspan ? cell.colspan : 1

            current_row << cell
            current_slots += colspan
            next unless current_slots >= col_count

            rows << Model::TableRow.new(columns: current_row)
            current_row = []
            current_slots = 0
          end

          rows << Model::TableRow.new(columns: current_row) if current_row.any?
          rows
        end

        # Infer a column count that consistently divides the colspan slots.
        # @param cells [Array<Model::TableCell>]
        # @return [Integer, nil]
        def infer_column_count(cells)
          return nil if cells.nil? || cells.empty?

          col_slots = cells.map do |cell|
            cell.is_a?(Model::TableCell) && cell.colspan ? cell.colspan : 1
          end
          total_cells = col_slots.sum

          possible_cols = (1..[total_cells, 12].min).select do |candidate|
            next false if candidate > total_cells
            next false if total_cells % candidate != 0

            slots_used = 0
            valid = true

            col_slots.each do |slots|
              slots_used += slots
              if slots_used == candidate
                slots_used = 0
              elsif slots_used > candidate
                valid = false
                break
              end
            end

            valid && slots_used.zero?
          end

          possible_cols.max || col_slots.first || 1
        end

        # Regroup parser-level rows into proper AsciiDoc rows.
        # The parser produces one "row" per line; this flattens all cells
        # and regroups by the cols attribute, then marks the first row as header.
        # @param rows [Array<Model::TableRow>]
        # @param attrs [Model::AttributeList, nil]
        # @return [Array<Model::TableRow>]
        def regroup_table_rows(rows, attrs = nil)
          return rows if rows.nil? || rows.empty?

          col_count = parse_cols_attribute(attrs)
          if col_count.nil? && rows.first.is_a?(Model::TableRow) && rows.first.columns.any?
            col_count = rows.first.columns.sum { |c| (c.colspan || 1).to_i }
          end

          all_cells = rows.flat_map do |r|
            r.is_a?(Model::TableRow) ? r.columns : []
          end

          return rows if all_cells.empty?

          grouped = group_cells_into_rows(all_cells, col_count)
          grouped.first.header = true unless grouped.empty?
          grouped
        end
      end
    end
  end
end
