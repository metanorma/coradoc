require_relative "../inline/anchor"

module Coradoc
  module Element
    module Block
      class Core
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

        def gen_anchor
          @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        end

        def gen_title
          t = Coradoc::Generator.gen_adoc(@title)
          return "" if t.empty?
          ".#{t}\n"
        end

        def gen_attributes
          @attributes.nil? ? "" : "#{@attributes.to_adoc}\n"
        end

        def gen_delimiter
          @delimiter_char * @delimiter_len
        end

        def gen_lines
          Coradoc::Generator.gen_adoc(@lines)
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
end
