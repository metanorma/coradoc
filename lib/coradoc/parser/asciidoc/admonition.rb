module Coradoc
  module Parser
    module Asciidoc
      module Admonition
        def admonition_type
          str("NOTE") | str("TIP") | str("EDITOR") |
            str("IMPORTANT") | str("WARNING") | str("CAUTION") |
            str("TODO")
          # requires atypical syntax for access?
          # | str('DANGER')
          # | str('SAFETY PRECAUTION')
        end

        def admonition_line
          admonition_type.as(:admonition_type) >> str(": ") >>
            (text.as(:text) >>
            line_ending.as(:line_break)
            ).repeat(1)
              .as(:content)
        end
      end
    end
  end
end
