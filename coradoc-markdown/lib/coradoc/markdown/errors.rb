# frozen_string_literal: true

module Coradoc
  module Markdown
    module Errors
      # Base error class for Markdown errors
      # Inherits from Coradoc::Error for unified error handling
      class Error < Coradoc::Error
      end

      # Raised when Markdown parsing fails
      class ParseError < Error
      end

      # Raised when Markdown serialization fails
      class SerializationError < Error
      end

      # Raised when an unsupported Markdown feature is encountered
      class UnsupportedFeatureError < Error
      end

      # Raised when Markdown-to-CoreModel transformation fails
      class TransformationError < Error
      end
    end
  end
end
