# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Table
        def self.call(element, context:)
          rows = Array(element.rows)
          return nil if rows.empty?

          head_rows, body_rows = partition_rows(rows)

          content = []
          content << build_table_head(head_rows, context) unless head_rows.empty?
          content << build_table_body(body_rows, context) unless body_rows.empty?

          return nil if content.empty?

          Node::Table.new(
            id: element.id,
            title: element.title,
            width: element.width,
            content: content
          )
        end

        class << self
          private

          def partition_rows(rows)
            head = rows.select { |r| r.is_a?(CoreModel::TableRow) && r.header }
            body = rows.reject { |r| r.is_a?(CoreModel::TableRow) && r.header }
            [head, body]
          end

          def build_table_head(rows, context)
            content = rows.map { |r| build_table_row(r, context) }
            Node::TableHead.new(content: content)
          end

          def build_table_body(rows, context)
            content = rows.map { |r| build_table_row(r, context) }
            Node::TableBody.new(content: content)
          end

          def build_table_row(row, context)
            cells = Array(row.cells).map { |c| build_table_cell(c, context) }
            Node::TableRow.new(content: cells)
          end

          def build_table_cell(cell, context)
            content = build_cell_content(cell, context)
            Node::TableCell.new(
              colspan: cell.colspan,
              rowspan: cell.rowspan,
              alignment: cell.alignment,
              header: cell.header || nil,
              content: content
            )
          end

          def build_cell_content(cell, context)
            if cell.is_a?(CoreModel::TableCell) && cell.children && !cell.children.empty?
              return cell.children.flat_map do |child|
                Handlers::Inline.process_child(child, context)
              end
            end

            text = cell.content
            return [] if text.nil? || text.to_s.empty?

            [context.text_node(text.to_s)]
          end
        end
      end
    end
  end
end
