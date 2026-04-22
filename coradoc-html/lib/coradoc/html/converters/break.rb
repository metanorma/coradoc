# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for Break (horizontal rule)
      class Break < Base
        class << self
          # Convert HTML <hr> to CoreModel::InlineElement (break)
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] Break inline element
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'break',
              metadata: { break_type: 'thematic' }
            )
          end

          # Convert CoreModel::InlineElement (break) to HTML <hr>
          # @param model [Coradoc::CoreModel::InlineElement] Break model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(model, _state = {})
            attributes = extract_model_attributes(model)
            build_element('hr', nil, attributes)
          end
        end
      end
    end
  end
end
