module Coradoc
  module Model
    module Block
      class SourceCode < Core
        attribute :delimiter_char, :string, default: -> { "-" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        asciidoc do
          map_model to: Coradoc::Element::Block::SourceCode
          map_attribute "delimiter_char", to: :delimiter_char
          map_attribute "delimiter_len", to: :delimiter_len
          map_attribute "lang", to: :lang
        end

        def to_asciidoc
          "\n\n#{gen_anchor}[source,#{@lang}]\n#{gen_delimiter}\n" <<
            gen_lines <<
            "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
