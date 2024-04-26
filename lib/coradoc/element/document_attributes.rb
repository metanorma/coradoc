module Coradoc
  module Element
    class DocumentAttributes
      attr_reader :data

      def initialize(data = {}, options = {})
        @data = data
        @options = options
      end

      def to_hash
        Hash.new.tap do |hash|
          data.each do |attribute|
            hash[attribute.key.to_s] = attribute.value.to_s.gsub("'", "")
          end
        end
      end
    end
  end
end
