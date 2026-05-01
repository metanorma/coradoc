# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      # Shared text extraction for Markdown model objects.
      #
      # Handles nil, plain strings, and Markdown::Text instances.
      module TextExtraction
        def extract_text(text)
          return '' if text.nil?
          return text.content.to_s if text.is_a?(Coradoc::Markdown::Text)

          text.to_s
        end
      end
    end
  end
end
