# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a single attribute (key-value pair) on an element
    #
    # @example
    #   attr = ElementAttribute.new(name: "role", value: "note")
    class ElementAttribute < Base
      attribute :name, :string
      attribute :value, :string

      # Convert to hash representation
      # @return [Hash] Single key-value pair
      def to_h
        { name => value }
      end

      # Convert to string representation (e.g., for serialization)
      # @return [String] Attribute in name="value" format
      def to_s
        %("#{name}="#{value}"")
      end
    end
  end
end
