module Coradoc
  module Element
    module Block
      class Pass < Core
        def initialize(
          id: nil,
          title: "",
          attributes: AttributeList.new,
          delimiter_len: 4,
          lines: []
        )
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
          @title = title
          @attributes = attributes
          @delimiter_char = "+"
          @delimiter_len = delimiter_len
          @lines = lines
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
