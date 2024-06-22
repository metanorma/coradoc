module Coradoc
  module Element
    class DocumentAttributes < Base
      attr_accessor :data

      declare_children :data

      def initialize(data = {}, options = {})
        @data = data
        @options = options
      end

      def to_hash
        @data.to_h do |attribute|
          [attribute.key.to_s, attribute.value.to_s.gsub("'", "")]
        end
      end

      def to_adoc
        adoc = ""
        to_hash.each do |key, value|
          adoc << ":#{key}: #{value}\n"
        end
        adoc
      end
    end
  end
end
