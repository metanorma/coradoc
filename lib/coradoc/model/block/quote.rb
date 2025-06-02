module Coradoc
  module Model
    module Block
      class Quote < Core
        attribute :delimiter_char, :string, default: -> { "_" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        asciidoc do
          map_model to: Coradoc::Element::Block::Quote
          map_attribute "delimiter_char", to: :delimiter_char
          map_attribute "delimiter_len", to: :delimiter_len
        end

        def to_asciidoc
          "\n\n#{gen_anchor}#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
