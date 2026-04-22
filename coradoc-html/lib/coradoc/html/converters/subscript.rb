# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Subscript inline element
      class Subscript < Base
        class << self
          # Convert HTML <sub> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Subscript inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'subscript',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (subscript) to HTML <sub>
          # @param model [Coradoc::CoreModel::InlineElement] Subscript model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('sub', content, attributes)
          end
        end
      end
    end
  end
end
