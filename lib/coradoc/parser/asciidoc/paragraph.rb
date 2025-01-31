module Coradoc
  module Parser
    module Asciidoc
      module Paragraph

        def line_not_text?
          line_start? >>
          (attribute_list >> newline).absent? >>
          block_delimiter.absent? >>
          list.absent? >>
          list_prefix.absent? >>
          list_continuation.absent? >>
          element_id.absent? >>
          section_prefix.absent?
        end

        def paragraph_text_line(many_breaks = false)
          tl = line_not_text? >>
          (asciidoc_char_with_id.absent? |
            element_id_inline >> literal_space? |
            line_start? >> line_not_text?) >>
            text_any.as(:text)
          if many_breaks == 0
            tl >> eof?
          elsif many_breaks
            tl >> (newline.as(:line_break)  | eof?)
          else
            tl >> (newline_single.as(:line_break) | eof? )
          end
        end

        def paragraph
          ( element_id.maybe >>
            block_title.maybe >>
            (attribute_list >> newline).maybe >>
            ((paragraph_text_line(0).repeat(1,1) >>
                   (newline.repeat(1).as(:line_break) | eof?)) |
              (paragraph_text_line(false)).repeat(1) >>
              (paragraph_text_line(true).repeat(1,1) >>
                   (newline.repeat(1).as(:line_break) | eof?)).repeat(0,1)
            ).as(:lines) >>
            (newline.repeat(0) | eof?)
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
