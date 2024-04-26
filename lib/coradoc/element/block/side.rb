module Coradoc
  module Element
    module Block
      class Side < Core
        def initialize(options = {})
          @lines = options.fetch(:lines, [])
          @delimiter_char = "*"
          @delimiter_len = options.fetch(:delimiter_len, 4)
        end

        def to_adoc
          "\n\n#{gen_delimiter}" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
