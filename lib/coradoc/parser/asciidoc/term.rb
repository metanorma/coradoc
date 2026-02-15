module Coradoc
  module Parser
    module Asciidoc
      module Term
        def term_type
          (str("term") |
            str("alt") |
            str("deprecated") |
            str("domain")).as(:term_type)
        end

        def term
          line_start? >>
            term_type >> str(":[") >>
            match('[^\]]').repeat(1).as(:term) >>
            str("]") >> str("\n").repeat(1).as(:line_break)
        end

        def footnote
          str("footnote:") >>
            keyword.as(:id).maybe >>
            str("[") >>
            match('[^\]]').repeat(1).as(:footnote) >>
            str("]")
        end

        def term_inline
          term_type >> str(":[") >>
            match('[^\]]').repeat(1).as(:term) >>
            str("]")
        end

        def term_inline2
          line_start? >>
            match('^\[') >> term_type >> str("]#") >>
            match('[^\#]').repeat(1).as(:term2) >> str("#")
        end
      end
    end
  end
end
