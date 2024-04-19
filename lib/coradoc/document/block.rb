module Coradoc
  module Document
    class Block
      attr_reader :title, :lines, :attributes, :lang, :id

      def initialize(title, options = {})
        @title = title
        @lines = options.fetch(:lines, [])
        @type_str = options.fetch(:type, nil)
        @delimiter = options.fetch(:delimiter, "")
        @attributes = options.fetch(:attributes, {})
        @lang = options.fetch(:lang, nil)
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
      end

      def type
        @type ||= defined_type || type_from_delimiter
      end

      class Side < Block
        def initialize(options = {})
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          lines = Coradoc::Generator.gen_adoc(@lines)
          "\n\n****" << lines << "\n****\n\n"
        end
      end

      class Example < Block
        def initialize(title, options = {})
          @title = title
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          title = ".#{@title}\n" unless @title.empty?
          lines = Coradoc::Generator.gen_adoc(@lines)
          "\n\n#{anchor}#{title}====\n" << lines << "\n====\n\n"
        end
      end

      class Quote < Block
        def initialize(title, options = {})
          @title = title
          @attributes = options.fetch(:attributes, nil)
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          attrs = @attributes.nil? ? "" : "#{@attributes.to_adoc}\n"
          lines = Coradoc::Generator.gen_adoc(@lines)
          "\n\n#{attrs}____\n" << lines << "\n____\n\n"
        end
      end

      class Literal < Block
        def initialize(title, options = {})
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          lines = Coradoc::Generator.gen_adoc(@lines)
          "\n\n#{anchor}....\n" << lines << "\n....\n\n"
        end
      end

      class SourceCode < Block
        def initialize(title, options = {})
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @lang = options.fetch(:lang, '')
          @lines = options.fetch(:lines, [])
          # super(title, options.merge({type: :literal}))
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          lines = Coradoc::Generator.gen_adoc(@lines)
          "\n\n#{anchor}[source,#{@lang}]\n----\n" << lines << "\n----\n\n"
        end
      end

      private

      def defined_type
        @type_str&.to_s&.to_sym
      end

      def type_from_delimiter
        type_hash.fetch(@delimiter, nil)
      end

      def type_hash
        @type_hash ||= {
          "____" => :quote,
          "****" => :side,
          "----" => :source,
          "====" => :example,
          "...." => :literal
        }
      end


    end
  end
end
