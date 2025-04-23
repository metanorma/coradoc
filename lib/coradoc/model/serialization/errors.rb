# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      # Base class for all AsciiDoc serialization errors
      class AsciidocError < StandardError; end

      # Raised when parsing invalid AsciiDoc content
      class ParseError < AsciidocError
        attr_reader :input, :line_number

        def initialize(message, input: nil, line_number: nil)
          @input = input
          @line_number = line_number
          super(message)
        end
      end

      # Raised when attribute mapping fails
      class MappingError < AsciidocError
        attr_reader :field_name, :value

        def initialize(message, field_name: nil, value: nil)
          @field_name = field_name
          @value = value
          super(message)
        end
      end

      # Raised when required fields are missing
      class ValidationError < AsciidocError
        attr_reader :field_name

        def initialize(message, field_name: nil)
          @field_name = field_name
          super(message)
        end
      end

      # Raised when trying to serialize invalid model state
      class SerializationError < AsciidocError
        attr_reader :object

        def initialize(message, object: nil)
          @object = object
          super(message)
        end
      end
    end
  end
end
