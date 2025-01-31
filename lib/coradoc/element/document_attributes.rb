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
          [attribute.key, attribute.value]
        end
      end

      def to_adoc
        to_hash.map do |key, value|
          v = if value.to_s.empty?
            ""
          elsif value.is_a? Array
            " #{value.join(',')}"
          else
            " #{value}"
          end
          ":#{key}:#{v}\n"
        end.join + "\n"
      end
    end
  end
end
