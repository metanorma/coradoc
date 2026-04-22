# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Underline inline element
      class Underline < Base
        class << self
          # Convert HTML <u> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Underline inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'underline',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (underline) to HTML <u>
          # @param model [Coradoc::CoreModel::InlineElement] Underline model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('u', content, attributes)
          end
        end
      end
    end
  end
end
