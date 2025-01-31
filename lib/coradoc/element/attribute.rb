module Coradoc
  module Element
    class Attribute < Base
      attr_accessor :key, :value

      def initialize(key, value, _options = {})
        @key = key.to_s
        if extensions_value?(value.to_s)
          @value = build_values(value.to_s)
        else
          @value = value.to_s.strip
        end
      end

      def extensions_value?(value)
        v = value.split(",").map(&:strip)
        v.intersect? %w[xml html pdf xml adoc rxl]
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
