module Coradoc
  module Document
    class Block
      class Example < Block
        def initialize(title, options = {})
          @title = title
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @lines = options.fetch(:lines, [])
          @delimiter_char = "="
          @delimiter_len = options.fetch(:delimiter_len, 4)
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_title}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
