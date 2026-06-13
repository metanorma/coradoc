# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module List
        def self.call(element, context:)
          items = Array(element.items).filter_map do |item|
            list_item(item, context: context)
          end
          return nil if items.empty?

          node_class = ordered?(element) ? Node::OrderedList : Node::BulletList
          node_class.new(
            id: element.id,
            start: element.is_a?(CoreModel::ListBlock) ? element.start : nil,
            content: items,
          )
        end

        class << self
          private

          def list_item(item, context:)
            content = build_item_content(item, context)
            return nil if content.empty?

            Node::ListItem.new(id: item.id, content: content)
          end

          def build_item_content(item, context)
            content = []

            has_children = item.is_a?(CoreModel::ListItem) &&
                           item.children && !item.children.empty?

            if has_children
              item.children.each do |child|
                node = dispatch_child(child, context)
                content << node if node
              end
            elsif item.content && !item.content.to_s.empty?
              content << context.text_node(item.content.to_s)
            end

            if item.is_a?(CoreModel::ListItem) && item.nested_list
              nested = Handlers::List.call(item.nested_list, context: context)
              content << nested if nested
            end

            content
          end

          def dispatch_child(child, context)
            case child
            when CoreModel::TextContent
              return nil if child.text.nil? || child.text.empty?
              context.text_node(child.text)
            when CoreModel::InlineElement
              Handlers::Inline.call(child, context: context)
            when CoreModel::Block, CoreModel::StructuralElement
              result = context.registry.handle(child, context: context)
              result&.first
            end
          end

          def ordered?(element)
            element.marker_type == "ordered"
          end
        end
      end
    end
  end
end
