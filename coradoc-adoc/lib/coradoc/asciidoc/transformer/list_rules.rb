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
                first_marker = nested.first.respond_to?(:marker) ? nested.first.marker : marker
                nested = if first_marker&.start_with?('.', '1', 'a', 'A', 'i', 'I')
                           Model::List::Ordered.new(items: nested)
                         else
                           Model::List::Unordered.new(items: nested)
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

            # Definition list term
            rule(dlist_term: simple(:term), delimiter: simple(:_delim)) do
              term.to_s
            end

            # Definition list item
            rule(
              definition_list_item: {
                terms: sequence(:terms),
                definition: simple(:contents)
              }
            ) do
              Model::List::DefinitionItem.new(terms: terms, contents: contents)
            end

            # Definition list item with hash terms (single term case)
            rule(
              definition_list_item: subtree(:item_data)
            ) do
              terms_data = item_data[:terms]
              definition = item_data[:definition]

              # Extract terms
              terms = if terms_data.is_a?(Array)
                        terms_data.map do |t|
                          if t.is_a?(Hash) && t[:dlist_term]
                            t[:dlist_term].to_s
                          else
                            t.to_s
                          end
                        end
                      else
                        [terms_data.to_s]
                      end

              # Extract definition
              if definition.is_a?(Parslet::Slice)
              end
              contents = definition.to_s

              Model::List::DefinitionItem.new(terms: terms, contents: contents)
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

            # List containing definition_list
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
