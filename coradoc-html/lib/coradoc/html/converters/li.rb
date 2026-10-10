# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Li < Base
        INSTANCE = new

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

          # Nested lists live in the canonical +nested_list+ slot
          # (single); remaining children carry inline content.
          nested = Array(content).find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
          children = nested ? Array(content).reject { |c| c.equal?(nested) } : content

          Coradoc::CoreModel::ListItem.new(
            children: children,
            nested_list: nested,
            id: id
          )
        end
      end

      register :li, Li::INSTANCE
    end
  end
end
