module Coradoc
  module Document
    class List
      attr_reader :items

      def initialize(items)
        @items = items
      end

      class Unnumbered < List
      end
    end
  end
end
