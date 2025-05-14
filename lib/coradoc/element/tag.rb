module Coradoc
  module Element
    class Tag < Base
      attr_accessor :name, :prefix, :attrs, :line_break

      def initialize(name:, prefix: "tag", attrs: AttributeList.new, line_break: "\n")
        @name = name
        @prefix = prefix
        @attrs = attrs
        @line_break = line_break
      end

      def to_adoc
        attrs = @attrs.to_adoc
        "// #{@prefix}::#{@name}#{attrs}#{@line_break}"
      end
    end
  end
end
