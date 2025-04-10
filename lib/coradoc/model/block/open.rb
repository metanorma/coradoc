module Coradoc
  module Model
    module Block
      class Open < Core
        attribute :delimiter_char, :string, default: -> { "-" }
        attribute :delimiter_len, :integer, default: -> { 2 }

        def to_asciidoc
          "\n\n#{gen_anchor}#{gen_attributes}#{gen_delimiter}\n" << gen_lines << "\n#{gen_delimiter}\n\n"
        end

      end
    end
  end
end
