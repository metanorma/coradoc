module Coradoc
  module Model
    module Block
      class Quote < Core
        attribute :delimiter_char, :string, default: -> { "_" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        def to_asciidoc
          "\n\n#{gen_title}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end

      end
    end
  end
end
