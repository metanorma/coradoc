# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Paragraph block element
      class Paragraph < Base
        class << self
          # Convert HTML <p> to CoreModel Block
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::Block] Block model with element_type: paragraph
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            attrs = extract_node_attributes(node)

            # Create paragraph block with content
            paragraph = Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              children: [content]
            )

            # Set ID if present
            paragraph.id = attrs[:id] if attrs[:id]

            paragraph
          end

          # Convert CoreModel::Block (element_type: paragraph) to HTML <p>
          # @param model [Coradoc::CoreModel::Block] Paragraph block model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            # Use renderable_content to handle both content and children
            content_to_render = model.respond_to?(:renderable_content) ? model.renderable_content : model.content
            content = convert_content_to_html(content_to_render, state)
            # Strip trailing whitespace from content to avoid issues with line breaks
            content = content.rstrip
            attributes = extract_model_attributes(model)
            build_element('p', content, attributes)
          end
        end
      end
    end
  end
end
