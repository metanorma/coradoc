module Coradoc
  module Element
    module Inline
      class CrossReference < Base
        attr_accessor :href, :args

        declare_children :href, :args

        def initialize(href:, args: nil)
          @href = href
          @args = args
          @args = nil if @args == ""
          @args = [@args] unless @args.is_a?(Array) || @args == nil
        end

        def to_adoc
          if @args
            args = @args.map { |a|
              Coradoc::Generator.gen_adoc(a)
            }.join(",")
            if args.empty?
              return "<<#{@href}>>"
            else
              return "<<#{@href},#{args}>>"
            end
          end
          "<<#{@href}>>"
        end
      end

      class CrossReferenceArg < Base
        attr_accessor :key, :delimiter, :value

        def initialize(key:, delimiter:, value:)
          @key = key
          @delimiter = delimiter
          @value = value
        end

        def to_adoc
          [@key, @delimiter, @value].join
        end
      end
    end
  end
end
