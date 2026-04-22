# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      class Attribute < Base
        attribute :key, :string
        attribute :value, :string, collection: true
        attribute :line_break, :string, default: -> { "\n" }

        private

        # Build values from comma-separated string
        # NOTE: This method allows for multiple values in format-specific attributes.
        def build_values(value)
          values = value.split(',').map(&:strip)
          values.length > 1 ? values : values.first
        end
      end
    end
  end
end
