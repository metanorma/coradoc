# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Superscript inline element
      class Superscript < Base
        class << self
          # Convert HTML <sup> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Superscript inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'superscript',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (superscript) to HTML <sup>
          # @param model [Coradoc::CoreModel::InlineElement] Superscript model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('sup', content, attributes)
          end
        end
      end
    end
  end
end
