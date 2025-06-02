module Coradoc
  module Element
    module Block
      class SourceCode < Core
        def initialize(
          title: nil,
          id: nil,
          lang: "",
          attributes: AttributeList.new,
          lines: [],
          delimiter_len: 4
        )
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
          @lang = lang
          @attributes = attributes
          @lines = lines
          @delimiter_char = "-"
          @delimiter_len = delimiter_len
        end

        def to_adoc
          "\n\n#{gen_anchor}#{gen_title}[source,#{@lang}]\n#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
