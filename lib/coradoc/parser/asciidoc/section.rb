module Coradoc
  module Parser
    module Asciidoc
      module Section
        def contents
          (
            bib_entry |
            block_image |
            tag |
            comment_block |
            comment_line |
            include_directive |
            admonition_line |
            block |
            table.as(:table) |
            # highlight.as(:highlight) |
            # glossaries.as(:glossaries) |
            paragraph |
            list |
            empty_line.as(:line_break)
          ).repeat(1)
        end

        def section_block(level = 2)
          return nil if level > 8

          (attribute_list >> newline).maybe >>
            element_id.maybe >>
            (attribute_list >> newline).maybe >>
            section_title(level).as(:title) >>
            contents.as(:contents).maybe
        end

        def section_prefix
          (line_start? >> match("^[=]") >> str("=").repeat(0) >> match('[^\n]'))
        end

        # Heading
        def section_title(level = 2, max_level = 8)
          line_start? >>
            match("=").repeat(level, max_level).as(:level) >>
            str("=").absent? >>
            space? >> text.as(:text) >> endline.as(:line_break)
        end

        # section
        def section(level = 2)
          r = section_block(level)
          if level < 8
            r = r >> section(level + 1).as(:section).repeat(0).as(:sections)
          end
          if level == 2
            r.as(:section)
          else
            r
          end
        end
      end
    end
  end
end
