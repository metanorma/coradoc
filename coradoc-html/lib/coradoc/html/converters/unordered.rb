# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Unordered (bulleted) lists
      class Unordered < Base
        class << self
          # Convert HTML <ul> to CoreModel::ListBlock
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::ListBlock] Unordered list model
          def to_coradoc(node, state = {})
            items = node.css('> li').map do |li_node|
              Coradoc::Html::Converters::ListItem.to_coradoc(li_node, state)
            end

            attrs = extract_node_attributes(node)

            list = Coradoc::CoreModel::ListBlock.new(
              marker_type: 'unordered',
              items: items
            )
            list.id = attrs[:id] if attrs[:id]

            list
          end

          # Convert CoreModel::ListBlock (unordered) to HTML <ul>
          # @param model [Coradoc::CoreModel::ListBlock] Unordered list model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            items_html = model.items.map do |item|
              Coradoc::Html::Converters::ListItem.to_html(item, state)
            end.join("\n")

            attrs = {}
            attrs[:id] = model.id if model.id

            build_element('ul', "\n#{items_html}\n", attrs)
          end
        end
      end
    end
  end
end
