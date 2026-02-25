# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Errors
        # Base error class for HTML input errors
        # Inherits from Coradoc::Error for unified error handling
        class Error < Coradoc::Error
        end

        # Raised when an unknown HTML tag is encountered
        class UnknownTagError < Error
        end

        # Raised when HTML input configuration is invalid
        class InvalidConfigurationError < Error
        end
      end
    end
  end
end
