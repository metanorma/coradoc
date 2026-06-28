# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Table < Base
        def build(node)
          rows = []
          node.content&.each do |child|
            next unless child.is_a?(Node)
            next unless %w[table_head table_body].include?(child.type)

            child.content&.each do |row_node|
              rows << build_node(row_node) if row_node.is_a?(Node)
            end
          end

          CoreModel::Table.new(title: node.attrs&.title, rows: rows)
        end
      end
    end
  end
end
