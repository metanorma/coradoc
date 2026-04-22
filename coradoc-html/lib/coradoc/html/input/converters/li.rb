# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Li < Base
          def to_coradoc(node, state = {})
            id = node['id']

            # Check if all children are <p> tags
            p_children = node.children.select { |child| child.name == 'p' }
            non_empty_children = node.children.reject { |c| c.text? && c.text.strip.empty? }

            content = if p_children.any? && p_children.size == non_empty_children.size && p_children.size == 1
                        # Single <p> tag - extract its content directly as inline content
                        treat_children_coradoc(p_children.first, state)
                      else
                        treat_children_coradoc(node, state)
                      end

            # Use CoreModel::ListItem with children for mixed content
            # content can be an array of inline elements or a single string
            Coradoc::CoreModel::ListItem.new(
              children: content,
              id: id
            )
          end
        end

        register :li, Li.new
      end
    end
  end
end
