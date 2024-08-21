module Coradoc
  module Element
    class Include
      attr_accessor :text

      def initialize(path, options = {})
        @path = path
        @attributes = options.fetch(:attributes, AttributeList.new)
        @line_break = options.fetch(:line_break, "\n")
      end

      def to_adoc
        attrs = @attributes.to_adoc(true)
        "include::#{@path}#{attrs}#{@line_break}"
      end
    end
  end
end
