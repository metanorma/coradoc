# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing list transformation rules
      module ListRules
        class << self
          def build_dlist_tree(items)
            root = Model::List::Definition.new(items: [])
            stack = [[root, 0]]

            items.each do |item|
              depth = dlist_depth(item.delimiter)
              stack.pop while stack.last[1] >= depth

              stack.last[0].items << item
              nested_list = Model::List::Definition.new(items: [])
              item.nested << nested_list
              stack.push([nested_list, depth])
            end

            prune_empty_nested(root)
            root
          end

          def dlist_depth(delimiter)
            delim = delimiter.to_s
            return 1 if delim == ';;' || delim.empty?

            [delim.count(':') - 1, 1].max
          end

          def prune_empty_nested(list)
            list.items.each do |item|
              item.nested.select! do |n|
                n.is_a?(Model::List::Definition) && n.items.any?
              end
              item.nested.each { |n| prune_empty_nested(n) }
            end
          end
        end

        def self.apply(transformer_class)
          transformer_class.class_eval do
            # List item
            rule(list_item: subtree(:list_item)) do
              marker = list_item[:marker]
              id = list_item[:id]
              text = list_item[:text]
              text = list_item[:text].to_s if list_item[:text].instance_of?(Parslet::Slice)
              attached = list_item[:attached]
              nested = list_item[:nested]
              line_break = list_item[:line_break]

              # Convert nested array to proper List object if needed
              if nested.is_a?(Array) && nested.any?
                nested = if nested.all?(Model::List::Core)
                           nested.first
                         elsif nested.all?(Model::List::Item)
                           first_marker = nested.first.marker
                           if first_marker.to_s.lstrip.start_with?('.', '1', 'a', 'A', 'i', 'I')
                             Model::List::Ordered.new(items: nested)
                           else
                             Model::List::Unordered.new(items: nested)
                           end
                         else
                           nested
                         end
              end

              Model::List::Item.new(
                content: text, id:, marker:, attached:, nested:, line_break:
              )
            end

            # List passthrough
            rule(list: simple(:list)) do
              list
            end

            # Unordered list
            rule(unordered: sequence(:list_items)) do
              Model::List::Unordered.new(items: list_items)
            end

            rule(
              attribute_list: simple(:attribute_list),
              unordered: sequence(:list_items)
            ) do
              Model::List::Unordered.new(items: list_items, attrs: attribute_list)
            end

            # Ordered list
            rule(ordered: sequence(:list_items)) do
              Model::List::Ordered.new(items: list_items)
            end

            rule(
              attribute_list: simple(:attribute_list),
              ordered: sequence(:list_items)
            ) do
              Model::List::Ordered.new(items: list_items, attrs: attribute_list)
            end

            # Definition list term (with optional anchor)
            rule(dlist_term: subtree(:term_data), delimiter: simple(:delim)) do
              case term_data
              when Hash
                text = term_data[:text]
                text = text.to_s if text.is_a?(Parslet::Slice) || text.is_a?(String)
                text = text.content.to_s if text.is_a?(Model::TextElement)
                id = term_data[:id]
                id = id.to_s if id.is_a?(Parslet::Slice)
                { text: text.to_s, id: id, delimiter: delim.to_s }
              when Model::TextElement
                { text: term_data.content.to_s, id: term_data.id, delimiter: delim.to_s }
              else
                { text: term_data.to_s, id: nil, delimiter: delim.to_s }
              end
            end

            # Definition list item
            rule(
              definition_list_item: {
                terms: sequence(:terms),
                definition: simple(:contents)
              }
            ) do
              term_strings = terms.map do |t|
                t.is_a?(Hash) ? t[:text].to_s : t.to_s
              end
              item_id = nil
              item_delim = '::'
              terms.each do |t|
                next unless t.is_a?(Hash)

                item_id = t[:id].to_s if t[:id]
                item_delim = t[:delimiter].to_s if t[:delimiter]
              end
              Model::List::DefinitionItem.new(terms: term_strings, contents: contents,
                                              id: item_id, delimiter: item_delim)
            end

            # Definition list item with hash terms (single term case)
            rule(
              definition_list_item: subtree(:item_data)
            ) do
              data = item_data.is_a?(Hash) ? item_data : { terms: Array(item_data), definition: '' }

              item_id = nil
              item_delim = '::'
              terms_data = data[:terms]
              definition = data[:definition].to_s

              terms = Array(terms_data).map do |t|
                case t
                when Hash
                  item_id ||= t[:id].to_s if t[:id]
                  item_delim = t[:delimiter].to_s if t[:delimiter]
                  t[:text].to_s
                else
                  t.to_s
                end
              end

              Model::List::DefinitionItem.new(terms: terms, contents: definition,
                                              id: item_id, delimiter: item_delim)
            end

            rule(definition_list: sequence(:list_items)) do
              ListRules.build_dlist_tree(list_items)
            end

            # Definition list with attribute_list (e.g., [%key])
            rule(
              attribute_list: simple(:attribute_list),
              definition_list: sequence(:list_items)
            ) do
              tree = ListRules.build_dlist_tree(list_items)
              tree.attrs = attribute_list if attribute_list
              tree
            end
          end
        end
      end
    end
  end
end
