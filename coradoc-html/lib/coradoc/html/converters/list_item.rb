# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for ListItem
      class ListItem < Base
        class << self
          # Convert HTML <li> to CoreModel::ListItem
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::ListItem] ListItem model
          def to_coradoc(node, state = {})
            attrs = extract_node_attributes(node)

            item = Coradoc::CoreModel::ListItem.new
            item.id = attrs[:id] if attrs[:id]

            # Extract content and nested lists
            content_nodes = []
            nested_list = nil

            node.children.each do |child|
              case child.name
              when 'ul', 'ol'
                # This is a nested list
                nested_list = convert_node_to_core(child, state)
              else
                content_nodes << child unless child.text.strip.empty? && child.name == 'text'
              end
            end

            # Convert content nodes - collect as mixed content array
            if content_nodes.any?
              content = content_nodes.flat_map { |n| convert_node_to_core(n, state) }.compact
              # Store as children for mixed content
              item.children = content if content.any?
            end

            item.nested = nested_list if nested_list

            item
          end

          # Convert CoreModel::ListItem to HTML <li>
          # @param model [Coradoc::CoreModel::ListItem] ListItem model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            parts = []

            # Convert main content - check children first (mixed content), then content
            content_to_render = model.respond_to?(:children) && model.children&.any? ? model.children : model.content
            parts << convert_content_to_html(content_to_render, state) if content_to_render

            # Convert attached content
            if model.respond_to?(:attached) && model.attached && !model.attached.empty?
              model.attached.each do |attached_item|
                parts << convert_content_to_html(attached_item, state)
              end
            end

            # Convert nested list
            parts << convert_content_to_html(model.nested, state) if model.respond_to?(:nested) && model.nested

            attrs = {}
            attrs[:id] = model.id if model.id

            build_element('li', parts.join("\n"), attrs)
          end
        end
      end
    end
  end
end
