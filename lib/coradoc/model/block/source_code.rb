module Coradoc
  module Model
    module Block
      class SourceCode < Core
        attribute :delimiter_char, :string, default: -> { "-" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        def to_asciidoc
          "\n\n#{gen_anchor}[source,#{@lang}]\n#{gen_delimiter}\n" <<
            gen_lines <<
            "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
