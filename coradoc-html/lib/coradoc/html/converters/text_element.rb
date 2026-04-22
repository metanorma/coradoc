# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for TextElement (plain text content)
      # In CoreModel, text is handled as plain strings
      class TextElement < Base
        class << self
          # Convert HTML text node to String
          # @param node [Nokogiri::XML::Node, String] HTML text node or string
          # @param state [Hash] Conversion state
          # @return [String] Plain text
          def to_coradoc(node, state = {})
            text = node.is_a?(String) ? node : node.text
            text = unescape_html(text) unless state[:skip_unescape]
            text
          end

          # Convert CoreModel content to HTML
          # @param model [String, CoreModel] Text content
          # @param state [Hash] Conversion state
          # @return [String] Plain text (escaped)
          def to_html(model, state = {})
            # Handle both string and model with content attribute
            content = if model.respond_to?(:content)
                        model.content
                      else
                        model
                      end

            return '' if content.nil?

            # Process content based on type
            case content
            when String
              escape_html(content)
            when Array
              content.map { |item| convert_content_to_html(item, state) }.join
            else
              escape_html(content.to_s)
            end
          end
        end
      end
    end
  end
end
