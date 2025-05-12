module Coradoc
  module Element
    module Block
      class Literal < Core
        def initialize(title:, id: nil, attributes: AttributeList.new,
lines: [], delimiter_len: 4)
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
          @attributes = attributes
          @lines = lines
          @delimiter_char = "."
          @delimiter_len = delimiter_len
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
