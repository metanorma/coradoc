module Coradoc
  module Parser
    module Asciidoc
      module Term
        def term_type
          (str("alt") | str("deprecated") | str("domain")).as(:term_type)
        end

        def term
          term_type >> str(':[') >>
          match('[^\]]').repeat(1).as(:term) >>
          str("]") >> str("\n").repeat(1).as(:line_break)
        end

        def term2
          match('^\[') >> term_type >> str(']#') >>
          match('[^\#]').repeat(1).as(:term2) >> str('#') >>
          str("]") >> str("\n").repeat(1).as(:line_break)
        end
      end
    end
  end
end
