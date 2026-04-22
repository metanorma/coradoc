# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Strikethrough inline element
      class Strikethrough < Base
        class << self
          # Convert HTML <del>, <s>, or <strike> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Strikethrough inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'strikethrough',
              content: content
            )
          end

          # Convert CoreModel::InlineElement (strikethrough) to HTML <del>
          # @param model [Coradoc::CoreModel::InlineElement] Strikethrough model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('del', content, attributes)
          end
        end
      end
    end
  end
end
