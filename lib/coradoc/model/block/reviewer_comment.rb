module Coradoc
  module Model
    module Block
      class ReviewerComment < Core
        attribute :delimiter_char, :string, default: -> { "*" }
        attribute :delimiter_len, :integer, default: -> { 4 }

        def to_asciidoc
          "\n\n#{gen_title}#{gen_attributes}#{gen_delimiter}\n" <<
            gen_lines <<
            "\n#{gen_delimiter}\n\n"
        end
      end
    end
  end
end
