module Coradoc
  module Document
    class Attribute
      attr_reader :key, :value

      def initialize(key, value, _options = {})
        @key = key.to_s
        @value = build_values(value.to_s)
      end

      private

      def build_values(value)
        values = value.split(",").map(&:strip)
        values.length > 1 ? values : values.first
      end
    end

    class Glossaries
      attr_reader :items

      def initialize(items)
        @items = items
      end
    end
  end
end
