module Coradoc
  module Element
    module Block
      class Quote < Core
        def initialize(
          title:,
          attributes: AttributeList.new,
          lines: [],
          delimiter_len: 4
        )
          @title = title
          @attributes = attributes
          @lines = lines
          @delimiter_char = "_"
          @delimiter_len = delimiter_len
        end

        def to_adoc
          "\n\n#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
