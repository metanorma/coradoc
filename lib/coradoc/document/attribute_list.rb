module Coradoc
  module Document
    class AttributeList
      attr_reader :positional, :named

      def initialize(*positional, **named)
        @positional = positional || []
        @named = named || {}
      end

      def add_positional(attr)
        @positional << attr
      end

      def add_named(name, value)
        @named[name] = value
      end

      def empty?
        @positional.empty? && @named.empty?
      end

      def to_adoc
        adoc = ""
        adoc << @positional.join(", ") if @positional.any?
        adoc << ", " if @positional.any? && @named.any?
        adoc << @named.map do |k, v|
          v2 = v.to_s
          v2 = v2.include?("\"") ? v2.gsub("\"","\\\"") : v2
          if v2.include?(" ") || v2.include?(",") || v2.include?("\"")
            v2 = "\"#{v2}\""
          end
          [k.to_s, "=", v2].join
        end.join(", ")
        adoc = "[#{adoc}]" if @positional.any? || @named.any?
        adoc
      end
    end
  end
end
