module Coradoc
  module Element
    class Tag < Base
      attr_accessor :name

      def initialize(tag_name, options = {})
        @tag_name = tag_name
        @prefix = options.fetch(:prefix, "tag")
        @attrs = options.fetch(:attribute_list, nil)
        @line_break = options.fetch(:line_break, "\n")
      end

      def to_adoc
        attrs = @attrs.to_adoc
        "// #{@prefix}::#{@tag_name}#{attrs}#{@line_break}"
      end
    end
  end
end
