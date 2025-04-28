# frozen_string_literal: true

module Coradoc
  module Model
    class Attribute < Base
      attribute :key, :string
      attribute :value, :string, collection: true
      attribute :line_break, :string, default: -> { "\n" }

      asciidoc do
        map_attribute "line_break", to: :line_break
      end

      def to_asciidoc
        _value = value.to_s.strip.delete("'")
        v = _value.empty? ? '' : " #{_value}"
        ":#{key}:#{v}#{line_break}"
      end

      private

      # TODO: convert to lutaml?
      # Initialize @value with build_values(value)
      # In the original code, this was done in the constructor
      # to allow for the possibility of multiple values
      # in the case of format-specific attributes.
      def build_values(value)
        values = value.split(",").map(&:strip)
        values.length > 1 ? values : values.first
      end
    end
  end
end
