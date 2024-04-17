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
      end

      def type
        @type ||= defined_type || type_from_delimiter
      end

      def to_adoc
        lines = Coradoc::Generator.gen_adoc(@lines)
        if type == :quote
          "\n\n#{@attributes}____\n" << lines << "\n____\n\n"
        elsif type == :source && @lang
          anchor = @id ? "[[#{@id}]]\n" : ""
          "\n\n#{anchor}[source,#{@lang}]\n----\n" << lines << "\n----\n\n"
        elsif type == :literal
          anchor = @id ? "[[#{@id}]]\n" : ""
          "\n\n#{anchor}....\n" << lines << "\n....\n\n"
        elsif type == :side
          "\n\n****\n" << lines << "\n****\n\n"
        elsif type == :example
          anchor = @id ? "[[#{@id}]]\n" : ""
          title = ".#{@title}\n" unless @title.empty?
          "\n\n#{anchor}#{title}====\n" << lines << "\n====\n\n"
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
