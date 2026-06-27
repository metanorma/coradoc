# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Shared logic for superscript/subscript converters.
      #
      # Subclasses must implement `element_class` returning the
      # CoreModel class (e.g., SuperscriptElement, SubscriptElement).
      module PositionalFormatting
        def to_coradoc(node, state = {})
          leading_whitespace, trailing_whitespace = extract_leading_trailing_whitespace(node)

          content = treat_children_coradoc(node, state)

          return nil if content_empty?(content)

          e = element_class.new(content: content)
          result = [leading_whitespace, e, trailing_whitespace].compact
          result.length == 1 ? result.first : result
        end

        private

        def content_empty?(content)
          return true if content.nil?
          return content.strip.empty? if content.is_a?(String)
          return content.empty? if content.is_a?(Array)

          false
        end
      end
    end
  end
end
