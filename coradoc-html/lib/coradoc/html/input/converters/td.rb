# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Td < Base
          def to_coradoc(node, state = {})
            colspan = node['colspan']&.to_i
            rowspan = node['rowspan']&.to_i
            alignment = extract_alignment(node)

            singlepara = node.elements.size == 1 && node.elements.first.name == 'p'
            state[:tdsinglepara] = singlepara if singlepara

            content = treat_children_coradoc(node, state)

            # Use CoreModel::TableCell
            Coradoc::CoreModel::TableCell.new(
              content: extract_text_from_content(content),
              alignment: alignment,
              colspan: colspan && colspan > 1 ? colspan : nil,
              rowspan: rowspan && rowspan > 1 ? rowspan : nil,
              header: node.name == 'th'
            )
          end

          def extract_alignment(node)
            align = node['align']
            case align
            when 'left' then 'left'
            when 'center' then 'center'
            when 'right' then 'right'
            end
          end
        end

        register :td, Td.new
        register :th, Td.new
      end
    end
  end
end
