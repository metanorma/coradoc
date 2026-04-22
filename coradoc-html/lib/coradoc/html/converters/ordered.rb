# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Ordered (numbered) lists
      class Ordered < Base
        class << self
          # Convert HTML <ol> to CoreModel::ListBlock
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::ListBlock] Ordered list model
          def to_coradoc(node, state = {})
            items = node.css('> li').map do |li_node|
              Coradoc::Html::Converters::ListItem.to_coradoc(li_node, state)
            end

            attrs = extract_node_attributes(node)

            list = Coradoc::CoreModel::ListBlock.new(
              marker_type: 'ordered',
              items: items
            )
            list.id = attrs[:id] if attrs[:id]

            # Extract start value if present
            list.start = attrs[:start].to_i if attrs[:start]

            list
          end

          # Convert CoreModel::ListBlock (ordered) to HTML <ol>
          # @param model [Coradoc::CoreModel::ListBlock] Ordered list model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            items_html = model.items.map do |item|
              Coradoc::Html::Converters::ListItem.to_html(item, state)
            end.join("\n")

            attrs = {}
            attrs[:id] = model.id if model.id

            # Add start attribute if not starting from 1
            attrs[:start] = model.start if model.respond_to?(:start) && model.start && model.start != 1

            build_element('ol', "\n#{items_html}\n", attrs)
          end
        end
      end
    end
  end
end
