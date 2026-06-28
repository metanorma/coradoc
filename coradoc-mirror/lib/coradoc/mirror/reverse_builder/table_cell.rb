# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class TableCell < Base
        def build(node)
          attrs = node.attrs
          CoreModel::TableCell.new(
            content: extract_text(node),
            header: attrs&.header || false,
            colspan: attrs&.colspan,
            rowspan: attrs&.rowspan,
            alignment: attrs&.alignment
          )
        end
      end
    end
  end
end
