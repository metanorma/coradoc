module Coradoc
  module Element
    class Tag < Base
      attr_accessor :name, :prefix, :attrs, :line_break

      def initialize(name, options = {})
        @name = name
        @prefix = options.fetch(:prefix, "tag")
        @attrs = options.fetch(:attribute_list, AttributeList.new)
        @line_break = options.fetch(:line_break, "\n")
      end

      def to_adoc
        attrs = @attrs.to_adoc
        "// #{@prefix}::#{@name}#{attrs}#{@line_break}"
      end
    end
  end
end
