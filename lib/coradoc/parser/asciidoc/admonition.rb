module Coradoc
  module Parser
    module Asciidoc
      module Admonition
        def admonition_type
          str('NOTE') | str('TIP') | str('EDITOR') |
          str('IMPORTANT') | str('WARNING') | str('CAUTION') |
          str('TODO') 
          # requires atypical syntax for access?
          # | str('DANGER')
          # | str('SAFETY PRECAUTION')
        end
        def admonition_line
          admonition_type.as(:admonition_type) >> str(': ') >>
          # (text_line.repeat(1).as(:content) |
          #   text_line.as(:text) >> line_ending.repeat(2).as(:line_break) |
          #   # (text.as(:text) >> line
          #   text_line.as(:text)
          #     # )
          #   )
          (
            text_line(1).repeat(1)
            ).as(:content)
        end
      end
    end
  end
end
