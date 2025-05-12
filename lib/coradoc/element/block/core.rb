require_relative "../inline/anchor"

module Coradoc
  module Element
    module Block
      class Core < Base
        attr_accessor :title, :lines, :attributes, :lang, :id

        declare_children :title, :lines, :attributes, :lang, :id

        def initialize(title:, id: nil, type: nil,
attributes: AttributeList.new, delimiter: "", lang: nil, lines: [])
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
          @type_str = type
          @attributes = attributes
          @delimiter = delimiter
          @lang = lang
          @lines = lines
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
