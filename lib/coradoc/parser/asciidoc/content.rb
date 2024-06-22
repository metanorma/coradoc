module Coradoc
  module Parser
    module Asciidoc
      module Content

        def highlight
          text_id >> newline >>
            underline >> highlight_text >> newline
        end

        def underline
          str("[underline]") | str("[.underline]")
        end

        def highlight_text
          str("#") >> words.as(:text) >> str("#")
        end

        def literal_space
          (match[" "] | match[' \t']).repeat(1)
        end

        # Override
        def literal_space?
          literal_space.maybe
        end

        # Text
        def text_line
          (comment_block.absent? >>
          comment_line.absent? >>
          include_directive.absent?)  >>
            (asciidoc_char_with_id.absent? | text_id) >> literal_space? >>
            text.as(:text) >> line_ending.as(:break)
        end

        def asciidoc_char
          match("^[*_:=-]")
        end

        def asciidoc_char_with_id
          asciidoc_char | str("[#") | str("[[")
        end

        def text_id
          str("[[") >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")
        end

        def glossary
          keyword.as(:key) >> str("::") >> (str(" ") | newline) >>
            text.as(:value) >> line_ending.as(:break)
        end

        def glossaries
          glossary.repeat(1)
        end

      end
    end
  end
end
