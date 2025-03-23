module Coradoc
  module Parser
    module Asciidoc
      module Citation
        def xref_anchor
          match("[^,>]").repeat(1).as(:href_arg).repeat(1, 1)
        end

        def xref_str
          match("[^,>]").repeat(1).as(:text)
        end

        def xref_arg
          (str("section") | str("paragraph") | str("clause") | str("annex") | str("table")).as(:key) >>
            match("[ =]").as(:delimiter) >>
            match("[^,>=]").repeat(1).as(:value)
        end

        def cross_reference
          (str("<<") >> xref_anchor >>
          ((str(",") >> xref_arg).repeat(1) |
            (str(",") >> xref_str).repeat(1)
          ).maybe >>
            str(">>")
          ).as(:cross_reference)
        end
      end
    end
  end
end
