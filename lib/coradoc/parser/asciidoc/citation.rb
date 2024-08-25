module Coradoc
  module Parser
    module Asciidoc
      module Citation
        def xref_anchor
          match('[^,>]').repeat(1).as(:href_arg).repeat(1,1)
        end

        def xref_str
          match('[^,>]').repeat(1).as(:text)
        end

        def xref_arg
          (str('section') | str('paragraph') | str('clause') | str('annex') | str('table')).as(:key) >>
          match('[ =]').as(:delimiter) >>
          match('[^,>=]').repeat(1).as(:value)
        end

        def cross_reference
          str('<<') >> xref_anchor >>
          ( (str(',') >> xref_arg).repeat(1) |
            (str(',') >> xref_str).repeat(1)
            ).maybe >>
            str('>>')
        end

        def citation_xref
          cross_reference.as(:cross_reference) >> newline |
          cross_reference.as(:cross_reference) >>
            (text_line.repeat(1)
            ).as(:comment).maybe
        end

        def citation_noxref
          (text_line.repeat(1)
          ).as(:comment)
        end

        def citation
          match('^[\[]') >> str(".source]\n") >>
          ( citation_xref |
            citation_noxref
          ).as(:citation)
        end
      end
    end
  end
end
