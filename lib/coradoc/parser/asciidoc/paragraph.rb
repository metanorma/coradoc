module Coradoc
  module Parser
    module Asciidoc
      module Paragraph

        def paragraph_text_line
          # include_directive.absent? >>
          # comment_block.absent? >>
          # comment_line.absent? >>
          # list.absent? >>
          # admonition_line.absent? >>
          # (match("^") >> attribute_list >> newline).absent? >>

          # block.absent? >>
          # match('^\[').absent? >>
          (asciidoc_char_with_id.absent? | text_id ) >>
          literal_space? >>
          (text_formatted.as(:text) # >>
          # newline_single.as(:break).maybe
          ) | term | term2
          #.as(:paragraph_text_line)
        end

        def paragraph
          # block.absent? >>
          # include_directive.absent? >>
          # comment_block.absent? >>
          # comment_line.absent? >>
          # list.absent? >>
          # admonition_line.absent? >>

          ( block_title.maybe >>
            (attribute_list >> newline).maybe >>
            (paragraph_text_line.repeat(1,1) >> any.absent? |
              (paragraph_text_line >> newline_single.as(:line_break)).repeat(1) >>
              (paragraph_text_line.repeat(1,1)).repeat(0,1)
            ).as(:lines) >>
            newline.repeat(0)
          ).as(:paragraph)
        end

        def paragraph_attributes
          str("[") >>
            keyword.as(:key) >> str("=") >>
            word.as(:value) >> str("]") >> newline
        end
      end
    end
  end
end
