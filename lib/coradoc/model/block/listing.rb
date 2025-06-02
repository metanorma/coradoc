module Coradoc
  module Model
    module Block
      class Listing < Core
        attribute :delimiter_char, :string, default: -> { "-" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        asciidoc do
          map_model to: Coradoc::Element::Block::Listing
          map_attribute "delimiter_char", to: :delimiter_char
          map_attribute "delimiter_len", to: :delimiter_len
        end

        def to_asciidoc
          "\n\n#{gen_anchor}#{gen_attributes}\n#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
