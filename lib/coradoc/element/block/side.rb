module Coradoc
  module Element
    module Block
      class Side < Core
        def initialize(
          title: "",
          attributes: AttributeList.new,
          delimiter_len: 4,
          lines: []
        )
          @title = title
          @attributes = attributes
          @delimiter_char = "*"
          @delimiter_len = delimiter_len
          @lines = lines
        end

        def to_adoc
          "\n\n#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
