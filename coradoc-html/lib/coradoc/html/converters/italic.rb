# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Italic inline element
      class Italic < Base
        class << self
          # Convert HTML <em> or <i> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Italic inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'italic',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (italic) to HTML <em>
          # @param model [Coradoc::CoreModel::InlineElement] Italic model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('em', content, attributes)
          end
        end
      end
    end
  end
end
