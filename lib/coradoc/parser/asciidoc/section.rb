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
          section_id.maybe >>
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
            space? >> text.as(:text) >> endline.as(:line_break)
        end

        # section
        def section
          section_block >> second_level_section.repeat(0).as(:sections)
        end

        def sub_section(level)
          newline.maybe >> section_block(level)
        end

        def second_level_section
          sub_section(3) >> third_level_section.repeat(0).as(:sections)
        end

        def third_level_section
          sub_section(4) >> fourth_level_section.repeat(0).as(:sections)
        end

        def fourth_level_section
          sub_section(5) >> fifth_level_section.repeat(0).as(:sections)
        end

        def fifth_level_section
          sub_section(6) >> sixth_level_section.repeat(0).as(:sections)
        end

        def sixth_level_section
          sub_section(7) >> sub_section(8).repeat(0).as(:sections)
        end
      end
    end
  end
end
