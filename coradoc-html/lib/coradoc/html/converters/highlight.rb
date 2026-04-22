# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Highlight inline element
      class Highlight < Base
        class << self
          # Convert HTML <mark> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Highlight inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'highlight',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (highlight) to HTML <mark>
          # @param model [Coradoc::CoreModel::InlineElement] Highlight model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('mark', content, attributes)
          end
        end
      end
    end
  end
end
