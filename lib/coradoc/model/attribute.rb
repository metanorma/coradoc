# frozen_string_literal: true

module Coradoc
  module Model
    class Attribute < Base
      attribute :key, :string
      attribute :value, :string, collection: true

      private

      # TODO: convert to lutaml?
      # Initialize @value with build_values(value)
      def build_values(value)
        values = value.split(",").map(&:strip)
        values.length > 1 ? values : values.first
      end
    end
  end
end
