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
    end
  end
end
