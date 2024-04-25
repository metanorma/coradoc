module Coradoc
  module Document
    class Block
      class Quote < Block
        def initialize(title, options = {})
          @title = title
          @attributes = options.fetch(:attributes, nil)
          @lines = options.fetch(:lines, [])
          @delimiter_char = "_"
          @delimiter_len = options.fetch(:delimiter_len, 4)
        end

        def to_adoc
          "\n\n#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
