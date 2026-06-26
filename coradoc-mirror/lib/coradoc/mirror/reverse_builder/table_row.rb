# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class TableRow < Base
        registers 'table_row'

        def build(node)
          cells = build_content(node).select { |c| c.is_a?(CoreModel::TableCell) }
          CoreModel::TableRow.new(cells: cells)
        end
      end
    end
  end
end
