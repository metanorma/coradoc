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
        data.to_h do |attribute|
          [attribute.key.to_s, attribute.value.to_s.gsub("'", "")]
        end
      end
    end
  end
end
