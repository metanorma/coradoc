module Coradoc
  module Element
    class DocumentAttributes < Base
      attr_accessor :data

      declare_children :data

      def initialize(data: {})
        @data = data
      end

      def to_adoc
        @data.map do |attribute|
          key, value, line_break = attribute.key, attribute.value, attribute.line_break
          v = if value.to_s.empty?
                ""
              elsif value.is_a? Array
                " #{value.join(',')}"
              else
                " #{value}"
              end
          ":#{key}:#{v}#{line_break}"
        end.join
      end
    end
  end
end
