# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing list transformation rules
      module ListRules
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
            rule(dlist_term: subtree(:term_data), delimiter: simple(:_delim)) do
              case term_data
              when Hash
                text = term_data[:text]
                text = text.to_s if text.is_a?(Parslet::Slice) || text.is_a?(String)
                text = text.content.to_s if text.is_a?(Model::TextElement)
                id = term_data[:id]
                id = id.to_s if id.is_a?(Parslet::Slice)
                { text: text.to_s, id: id }
              when Model::TextElement
                { text: term_data.content.to_s, id: term_data.id }
              else
                { text: term_data.to_s, id: nil }
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
              terms.each do |t|
                next unless t.is_a?(Hash) && t[:id]

                item_id = t[:id].to_s
                break
              end
              Model::List::DefinitionItem.new(terms: term_strings, contents: contents, id: item_id)
            end

            # Definition list item with hash terms (single term case)
            rule(
              definition_list_item: subtree(:item_data)
            ) do
              data = item_data.is_a?(Hash) ? item_data : { terms: Array(item_data), definition: '' }

              item_id = nil
              terms_data = data[:terms]
              definition = data[:definition].to_s

              terms = Array(terms_data).map do |t|
                case t
                when Hash
                  item_id ||= t[:id].to_s if t[:id]
                  t[:text].to_s
                else
                  t.to_s
                end
              end

              Model::List::DefinitionItem.new(terms: terms, contents: definition, id: item_id)
            end

            rule(definition_list: sequence(:list_items)) do
              Model::List::Definition.new(items: list_items)
            end

            # Definition list with attribute_list (e.g., [%key])
            rule(
              attribute_list: simple(:attribute_list),
              definition_list: sequence(:list_items)
            ) do
              Model::List::Definition.new(items: list_items, attrs: attribute_list)
            end
          end
        end
      end
    end
  end
end
