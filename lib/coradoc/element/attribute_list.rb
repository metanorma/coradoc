module Coradoc
  module Element
    class AttributeList < Base
      attr_accessor :positional, :named, :rejected_positional, :rejected_named

      declare_children :positional, :named

      def initialize(*positional, **named)
        @positional = positional || []
        @named = named || {}
        @rejected_positional = []
        @rejected_named = []
      end

      def add_positional(*attr)
        @positional += attr
      end

      def add_named(name, value)
        @named[name] = value
      end

      def any?
        !empty?
      end

      def empty?
        @positional.empty? && @named.empty?
      end

      def validate_attr(attr, matcher)
        matcher === attr
      end

      def validate_positional(validators)
        @positional.each_with_index do |value, i|
          # TODO: Decide what to do with this value
          _positional_name = validators[i][0]

          validator = validators[i][1]

          unless validator && validate_attr(value, validator)
            @positional[i] = nil
            @rejected_positional << [i, value]
          end
        end

        @positional.pop while !@positional.empty? && @positional.last.nil?
      end

      def validate_named(validators)
        @named.each_with_index do |(name, value), i|
          name = name.to_sym
          validator = validators[name]

          unless validator && validate_attr(value, validator)
            @named.delete(name)
            @rejected_named << [name, value]
          end
        end
      end

      def to_adoc(show_empty = true)
        return "[]" if [@positional, @named].all?(:empty?)

        adoc = +""
        if !@positional.empty?
          adoc << @positional.map { |p| [nil, ""].include?(p) ? '""' : p }.join(",")
        end
        adoc << "," if @positional.any? && @named.any?
        adoc << @named.map do |k, v|
          if v.is_a?(String)
            v = v.gsub("\"", "\\\"")
            if v.include?(" ") || v.include?(",") || v.include?('"')
              v = "\"#{v}\""
            end
          elsif v.is_a?(Array)
            v = "\"#{v.join(',')}\""
          end
          [k.to_s, "=", v].join
        end.join(",")

        if !empty? || (empty? && show_empty)
          "[#{adoc}]"
        elsif empty? && !show_empty
          adoc
        end
      end

      module Matchers
        def one(*args)
          One.new(*args)
        end

        class One
          def initialize(*possibilities)
            @possibilities = possibilities
          end

          def ===(other)
            @possibilities.any? { |i| i === other }
          end
        end

        def many(*args)
          Many.new(*args)
        end

        # TODO: Find a way to only reject some values but not all?
        class Many
          def initialize(*possibilities)
            @possibilities = possibilities
          end

          def ===(other)
            other = other.split(",") if other.is_a?(String)

            other.is_a?(Array) &&
              other.all? { |i| @possibilities.any? { |p| p === i } }
          end
        end
      end
    end
  end
end
