module Coradoc
  module Element
    module Block
      class Pass < Core
        def initialize(options = {})
          @title = options.fetch(:title, "")
          @attributes = options.fetch(:attributes, AttributeList.new)
          @delimiter_char = "+"
          @delimiter_len = options.fetch(:delimiter_len, 4)
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          "\n\n#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
