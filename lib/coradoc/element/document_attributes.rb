module Coradoc
  module Element
    class DocumentAttributes < Base
      attr_accessor :data

      declare_children :data

      def initialize(data: {})
        @data = data
      end

      def to_adoc
        @data.map { |attribute|
          key = attribute.key
          value = attribute.value
          line_break = attribute.line_break
          v = if value.to_s.empty?
                ""
              elsif value.is_a? Array
                " #{value.join(',')}"
              else
                " #{value}"
              end
          ":#{key}:#{v}#{line_break}"
        }.join + "\n"
      end
    end
  end
end
