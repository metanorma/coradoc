# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Bold inline element
      class Bold < Base
        class << self
          # Convert HTML <strong> or <b> to CoreModel::InlineElement
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Bold inline element
          def to_coradoc(node, state = {})
            content = treat_children(node, state)
            Coradoc::CoreModel::BoldElement.new(
              content: content
            )
          end

          # Convert CoreModel::InlineElement (bold) to HTML <strong>
          # @param model [Coradoc::CoreModel::InlineElement] Bold model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, state = {})
            content = convert_content_to_html(model.content, state)
            attributes = extract_model_attributes(model)
            build_element('strong', content, attributes)
          end
        end
      end
    end
  end
end
