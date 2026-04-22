# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for LineBreak inline element
      class LineBreak < Base
        class << self
          # Convert HTML <br> to CoreModel::InlineElement (break)
          # @param node [Nokogiri::XML::Node] HTML node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] LineBreak inline element
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'break',
              metadata: { break_type: 'line' }
            )
          end

          # Convert CoreModel::InlineElement (break with line type) to HTML <br>
          # @param model [Coradoc::CoreModel::InlineElement] LineBreak model
          # @param state [Hash] Conversion state
          # @return [String] HTML string
          def to_html(_model, _state = {})
            build_element('br')
          end
        end
      end
    end
  end
end
