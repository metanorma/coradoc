# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:tbl (Table) elements to CoreModel::Table.
        #
        # Walks the OOXML table structure (Table → TableRow → TableCell)
        # and produces the corresponding CoreModel tree.
        #
        # Cell paragraphs are transformed through the rule system to preserve
        # inline formatting (bold, italic, links) as InlineElement objects.
        # Print-layout properties (frame, grid, width) are NOT mapped — CoreModel
        # is a semantic model, not a print layout language.
        class TableRule < Rule
          include OrderedContent

          def matches?(element)
            defined?(Uniword::Wordprocessingml::Table) &&
              element.is_a?(Uniword::Wordprocessingml::Table)
          end

          def apply(table, context)
            CoreModel::Table.new(
              rows: table.rows.map { |r| transform_row(r, context) }
            )
          end

          private

          def transform_row(row, context)
            CoreModel::TableRow.new(
              cells: row.cells.map { |c| transform_cell(c, context) },
              header: row_header?(row)
            )
          end

          # The persisted header flag lives in w:trPr/w:tblHeader
          # (row.properties.tbl_header); TableRow#header? is a runtime-only
          # accessor that deserialized documents never populate.
          def row_header?(row)
            tbl_header = row.properties&.tbl_header
            return row.header? unless tbl_header.is_a?(Uniword::Wordprocessingml::ValInt)

            # <w:tblHeader/> without w:val means "on" (ST_OnOff semantics)
            return true if tbl_header.value.nil?

            tbl_header.value.to_i.positive?
          end

          def transform_cell(cell, context)
            inline_children = cell_paragraphs(cell).flat_map do |para|
              extract_inline_from_paragraph(para, context)
            end

            props = cell.properties

            CoreModel::TableCell.new(
              content: extract_plain_text(inline_children),
              alignment: props&.vertical_align&.to_s,
              colspan: cell.column_span,
              rowspan: cell.row_span,
              header: header_cell?(cell),
              children: inline_children
            )
          end

          # Transform a cell paragraph and extract its inline children
          def extract_inline_from_paragraph(para, context)
            transformed = context.transform(para)
            return [] unless transformed

            # If it's a Block with children (inline elements), extract them
            if transformed.is_a?(CoreModel::Block) && transformed.children.any?
              transformed.children
            elsif transformed.is_a?(CoreModel::Block)
              [transformed.content].compact
            else
              [transformed]
            end
          end

          def cell_paragraphs(cell)
            cell.paragraphs || []
          end

          def header_cell?(cell)
            return false unless cell.properties

            vm = cell.properties.v_merge
            vm&.value.to_s == 'restart'
          end
        end
      end
    end
  end
end
