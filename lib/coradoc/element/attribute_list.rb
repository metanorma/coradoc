module Coradoc
  module Element
    class AttributeList
      attr_reader :positional, :named, :rejected_positional, :rejected_named

      def initialize(*positional, **named)
        @positional = positional || []
        @named = named || {}
        @rejected_positional = []
        @rejected_named = []
      end

      def add_positional(*attr)
        attr.each{|a| @positional << a}
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
          if !validators[i][1].is_a?(Array)
            result = validate_attr(value, validators[i][1])
          elsif validators[i][1].is_a?(Array)
            result = validators[i][1].map do |v|
              validate_attr(value, v)
            end.any?
          end
          if result
          else
            @positional[i] = nil
            @rejected_positional << [i, value]
          end
        end
      end

      def validate_named(validators)
        @named.each_with_index do |pair, i|
          name = pair[0].to_sym
          value = pair[1]
          # validators.each do |vdtr|
          if validators[name]
            if !validators[name].is_a?(Array)
              res = validate_attr(value, validators[name])
            elsif validators[name].is_a?(Array)
              res = validators[name][1..-1].map do |vdtr|
                validate_attr(value, vdtr)
              end
            end
          else
            res = false
          end
            # results << vdtr.map do |vd|
            #   has_name = vd.keys.include?(name)
            #   has_value = has_name ? validate_n(value, vd[name]) : false
            #   has_value
            # end
          # end
          if res == true || (res.is_a?(Array) && res.any?)
          else
            @named.delete(name)
            @rejected_named << [name, value]
          end
        end
      end

      def to_adoc(show_empty = true)
        return "[]" if [@positional, @named].all?(:empty?)

        adoc = ""
        if @positional.any?
          adoc << @positional.map{|p| p == "" ? "\"\"" : p}.join(",")
        end
        adoc << "," if @positional.any? && @named.any?
        adoc << @named.map do |k, v|
          if v.is_a?(String)
            v2 = v.to_s
            v2 = v2.include?("\"") ? v2.gsub("\"", "\\\"") : v2
            if v2.include?(" ") || v2.include?(",") || v2.include?("\"")
              v2 = "\"#{v2}\""
            end
          elsif v.is_a?(Array)
            v2 = "\"#{v.join(',')}\""
          end
          [k.to_s, "=", v2].join
        end.join(",")
        if !empty? || (empty? && show_empty)
          "[#{adoc}]"
        elsif empty? && !show_empty
          adoc
        end
      end
    end
  end
end
