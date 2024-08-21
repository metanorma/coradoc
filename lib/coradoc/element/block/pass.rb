module Coradoc
  module Element
    module Block
      class Pass < Core
        def initialize(options = {})
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @title = options.fetch(:title, "")
          @attributes = options.fetch(:attributes, AttributeList.new)
          @delimiter_char = "+"
          @delimiter_len = options.fetch(:delimiter_len, 4)
          @lines = options.fetch(:lines, [])
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
