module Coradoc
  module Element
    module Block
      class Listing < Core
        def initialize(_title, options = {})
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @lang = options.fetch(:lang, "")
          @attributes = options.fetch(:attributes, AttributeList.new)
          @lines = options.fetch(:lines, [])
          @delimiter_char = "-"
          @delimiter_len = options.fetch(:delimiter_len, 4)
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_attributes}\n#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
