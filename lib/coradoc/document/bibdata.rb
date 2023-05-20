module Coradoc
  module Document
    class Bibdata
      attr_reader :data

      def initialize(bibdata, options = {})
        @bibdata = bibdata
        @options = options
      end

      def data
        @data ||= @bibdata
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
