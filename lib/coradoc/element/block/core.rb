require_relative "../inline/anchor"

module Coradoc
  module Element
    module Block
      class Core < Base
        attr_accessor :title, :lines, :attributes, :lang, :id

        declare_children :title, :lines, :attributes, :lang, :id

        def initialize(title, options = {})
          @title = title
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @type_str = options.fetch(:type, nil)
          @attributes = options.fetch(:attributes, AttributeList.new)
          @delimiter = options.fetch(:delimiter, "")
          @lang = options.fetch(:lang, nil)
          @lines = options.fetch(:lines, [])
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
          attrs = @attributes.to_adoc(false)
          return "#{attrs}\n" if !attrs.empty?

          ""
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
            "====" => :example,
            "...." => :literal,
            "--"   => :open,
            "++++" => :pass,
            "____" => :quote,
            "****" => :side,
            "----" => :source,
          }
        end
      end
    end
  end
end
