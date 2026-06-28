# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class ListItem < Base
        LIST_TYPES = %w[bullet_list ordered_list].freeze
        private_constant :LIST_TYPES

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join

          CoreModel::ListItem.new(
            content: text,
            children: children,
            nested_list: find_nested_list(node)
          )
        end

        private

        def find_nested_list(node)
          node.content&.each do |child|
            next unless child.is_a?(Node)
            return build_node(child) if LIST_TYPES.include?(child.type)
          end
          nil
        end
      end
    end
  end
end
