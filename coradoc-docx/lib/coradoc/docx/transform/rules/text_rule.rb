# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:t (Text) elements to plain strings.
        #
        # Text is returned as a raw string — not wrapped in a CoreModel node.
        # The caller (RunRule) is responsible for wrapping in InlineElement
        # when formatting is present.
        class TextRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::Text) &&
              element.is_a?(Uniword::Wordprocessingml::Text)
          end

          def apply(text, _context)
            text.content.to_s
          end
        end
      end
    end
  end
end
