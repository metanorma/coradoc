# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Monospace inline element
      class Monospace < Base
        class << self
          # Convert HTML <code> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Monospace inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'monospace',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (monospace) to HTML <code>
          # @param model [Coradoc::CoreModel::InlineElement] Monospace model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('code', content, attributes)
          end
        end
      end
    end
  end
end
