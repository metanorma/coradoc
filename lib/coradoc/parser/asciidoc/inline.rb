module Coradoc
  module Parser
    module Asciidoc
      module Inline

        def cross_reference
          str('<<') >> match("[^,>]").repeat(1).as(:href) >>
          (str(',') >> match("[^>]").repeat(1).as(:name)).maybe >>
          str('>>')
        end

        def citation
          (str("[.source]\n") >>
            cross_reference.as(:cross_reference) >>
            (match['[^\n]'].repeat(1)).as(:comment).maybe >>
            newline).as(:citation)
        end

        def bold_constrained
          (str('*') >>
            match("[^*]").repeat(1).as(:text).repeat(1,1) >>
             str('*')  >> str('*').absent?
            ).as(:bold_constrained)
        end

        def bold_unconstrained
          (str('**') >>
            match("[^*\n]").repeat(1).as(:text).repeat(1,1) >>
             str('**')
            ).as(:bold_unconstrained)
        end

        def highlight_constrained
          (str('#') >>
            match('[^#]').repeat(1).as(:text).repeat(1,1) >>
             str('#') >> str('#').absent?
            ).as(:highlight_constrained)
        end

        def highlight_unconstrained
          (str('##') >>
            match('[^#]').repeat(1).as(:text).repeat(1,1) >>
             str('##')
            ).as(:highlight_unconstrained)
        end

        def italic_constrained
          (str('_') >>
            match('[^_]').repeat(1).as(:text).repeat(1,1) >>
             str('_') >> str('_').absent?
            ).as(:italic_constrained)
        end

        def italic_unconstrained
          (str('__') >>
            match('[^_]').repeat(1).as(:text).repeat(1,1) >>
             str('__')
            ).as(:italic_unconstrained)
        end

        def text_unformatted
          (admonition_line.absent? >>
          (cross_reference.absent? |
            bold_unconstrained.absent? |
            bold_constrained.absent? |
            highlight_unconstrained.absent? |
            highlight_constrained.absent? |
            italic_unconstrained.absent? |
            italic_constrained.absent?) >>
            match('[^\n]').repeat(1)
            )
        end

        def text_formatted
           ((cross_reference |
            bold_unconstrained | bold_constrained |
            highlight_unconstrained | highlight_constrained |
            italic_unconstrained | italic_constrained )|
            text_unformatted).repeat(1)
           
        end
      end
    end
  end
end
