module Coradoc
  module Parser
    module Asciidoc
      module Content
        def literal_space
          (match[" "] | match[' \t']).repeat(1)
        end

        # Override
        def literal_space?
          literal_space.maybe
        end

        def list_prefix
          (line_start? >>
            (match("^[*]") >> str("*").repeat(1, 5) |
            match('^[\.]') >> str(".").repeat(1, 5)) >>
            str(" "))
        end

        # Text
        # :zero :one :many
        def text_line(many_breaks = false)
          tl = (asciidoc_char_with_id.absent? | element_id_inline) >>
            literal_space? >> text_any.as(:text)
          if many_breaks
            tl >> (line_ending.repeat(1).as(:line_break) | eof?)
          else
            tl >> (line_ending.as(:line_break) | eof?)
          end
        end

        def asciidoc_char
          line_start? >> match['*_:+=\-']
        end

        def asciidoc_char_with_id
          asciidoc_char | str("[#") | str("[[")
        end

        def element_id
          line_start? >>
            (str("[[") >> keyword.as(:id) >> str("]]") |
               str("[#") >> keyword.as(:id) >> str("]")
            ) >> newline
        end

        def element_id_inline
          str("[[") >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")
        end

        def glossary
          keyword.as(:key) >> str("::") >> (str(" ") | newline) >>
            text.as(:value) >> line_ending.as(:line_break)
        end

        def glossaries
          glossary.repeat(1)
        end
      end
    end
  end
end
