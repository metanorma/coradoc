module Coradoc
  module Parser
    module Asciidoc
      module Section

        def contents
          (
            citation |
            comment_block |
            comment_line |
            include_directive |
            admonition_line |
            block.as(:block) |
            table.as(:table) |
            highlight.as(:highlight) |
            glossaries.as(:glossaries) |
            paragraph |
            list |
            empty_line
          ).repeat(1)
        end

        def citation
          (str("[.source]\n") >> cross_reference.as(:reference) ).as(:citation)
        end

        def section_block(level = 2)
          return nil if level > 8
          section_id.maybe >>
            (attribute_list >> newline).maybe >>
            section_title(level).as(:title) >>
            contents.as(:contents).maybe
        end

        # Section id
        def section_id
          (str("[[") >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")) >> newline
        end

        # Heading
        def section_title(level = 2, max_level = 8)
          match("=").repeat(level, max_level).as(:level) >>
            str('=').absent? >>
            space? >> text.as(:text) >> endline.as(:line_break)
        end

        # section
        def section(level = 2)
          r = section_block(level) 
          if level < 8
            r = r >> section(level + 1).as(:section).repeat(0).as(:sections)
          end
          if level == 2
            (r).as(:section)
          else
            r
          end

        end

      end
    end
  end
end
