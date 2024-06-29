module Coradoc
  module Parser
    module Asciidoc
      module Bibliography

        def bibliography
          (section_id.maybe >>
          str("[bibliography]\n") >>
          str("== ") >> match("[^\n]").repeat(1).as(:title) >> str("\n") >>
          bib_entry.repeat(1).as(:entries)
          ).as(:bibliography)
        end

        def bib_entry
          (str('* [[[') >> match('[^,\]\n]').repeat(1).as(:anchor_name) >>
          (  str(",") >>
            match('[^\]\n]').repeat(1).as(:document_id)
            ).maybe  >>
          str("]]]") >>
            (text_line.repeat(0,1) >>
              text_line.repeat(0)
            ).as(:reference_text) >>
            line_ending.repeat(1).as(:line_break).maybe
          ).as(:bibliography_entry)
        end
      end
    end
  end
end
