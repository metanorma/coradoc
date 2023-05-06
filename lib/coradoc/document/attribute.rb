module Coradoc
  module Document
    class Attribute
      attr_reader :key, :value

      def initialize(key, value, _options = {})
        @key = key
        @value = value
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
