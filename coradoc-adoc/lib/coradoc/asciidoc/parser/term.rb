# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Term
        def term_type
          (str('term') |
            str('alt') |
            str('deprecated') |
            str('domain')).as(:term_type)
        end

        def term
          line_start? >>
            term_type >> str(':[') >>
            match('[^\]]').repeat(1).as(:term) >>
            str(']') >> str("\n").repeat(1).as(:line_break)
        end

        # Content that may contain nested macro:[...] patterns
        # Handles balanced brackets for nested macros like stem:[x], term:[y]
        def macro_content
          # Match content that is either:
          # 1. Any character that is not ]
          # 2. Or a complete nested macro like stem:[...] where the content
          #    itself can contain nested macros
          (
            # Non-bracket character (but not starting a macro keyword)
            (macro_keyword.absent? >> match('[^\]]')) |
            # A complete nested macro
            nested_macro
          ).repeat(0)
        end

        # Keywords that start macros
        def macro_keyword
          str('stem') | str('term') | str('footnote') |
            str('latexmath') | str('asciimath') | str('alt') |
            str('deprecated') | str('domain')
        end

        # A nested macro: keyword:[content]
        def nested_macro
          macro_keyword >> str(':[') >> macro_content >> str(']')
        end

        def footnote
          str('footnote:') >>
            keyword.as(:id).maybe >>
            str('[') >>
            macro_content.as(:footnote) >>
            str(']')
        end

        def term_inline
          term_type >> str(':[') >>
            match('[^\]]').repeat(1).as(:term) >>
            str(']')
        end

        def term_inline2
          line_start? >>
            match('^\[') >> term_type >> str(']#') >>
            match('[^\#]').repeat(1).as(:term2) >> str('#')
        end
      end
    end
  end
end
