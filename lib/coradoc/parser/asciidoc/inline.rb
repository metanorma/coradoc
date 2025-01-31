module Coradoc
  module Parser
    module Asciidoc
      module Inline

        def attribute_reference
          str('{').present? >> str('{') >>
            match('[a-zA-Z0-9_-]').repeat(1).as(:attribute_reference) >>
            str('}')
        end

        def bold_constrained
          (str('*').present? >> str('*') >>
            match("[^*]").repeat(1).as(:text).repeat(1,1) >>
             str('*')  >> str('*').absent? >>
             str("\n\n").absent?
            ).as(:bold_constrained)
        end

        def bold_unconstrained
          (str('**').present? >> str('**') >>
            match("[^*]").repeat(1).as(:text).repeat(1,1) >>
             str('**')
            ).as(:bold_unconstrained)
        end

        def span_constrained
          (attribute_list >> 
            str('#') >>
            match('[^#]').repeat(1).as(:text) >>
             str('#') >> str('#').absent?
            ).as(:span_constrained)
        end

        def span_unconstrained
          (attribute_list >> 
            str('##') >>
            match('[^#]').repeat(1).as(:text) >>
             str('##')
            ).as(:span_unconstrained)
        end

        def italic_constrained
          (str('_') >> str('_').absent? >>
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


        def monospace_constrained
          (str('`') >>
            match('[^`]').repeat(1).as(:text).repeat(1,1) >>
             str('`') >> str('`').absent?
            ).as(:monospace_constrained)
        end

        def monospace_unconstrained
          (str('``') >>
            match('[^`]').repeat(1).as(:text).repeat(1,1) >>
             str('``')
            ).as(:monospace_unconstrained)
        end

        def superscript
          (str("^") >>
            match('[^^]').repeat(1).as(:text).repeat(1,1) >>
             str("^")
            ).as(:superscript)
        end

        def subscript
          (str("~") >>
            match('[^~]').repeat(1).as(:text).repeat(1,1) >>
             str("~")
            ).as(:subscript)
        end

        def span
          attribute_list >> 
          (str('#') >>
            match('[^#]').repeat(1).as(:text) >>
             str('#') >> str('#').absent?
          ).as(:span)
        end

        def inline_chars?
          match('[\[*#_{<^~`]').present? |
          term_type.present? |
          str('footnote').present?
        end

        def inline
          bold_unconstrained |
          bold_constrained |
          span_unconstrained |
          span_constrained |
          italic_unconstrained |
          italic_constrained |
          highlight_unconstrained |
          highlight_constrained |
          monospace_unconstrained |
          monospace_constrained |
          superscript |
          subscript |
          attribute_reference |
          cross_reference |
          term_inline |
          term_inline2 |
          footnote
        end

        def text_unformatted
          # line_not_text? >>
          (inline.absent? >>
            match("[^\n]") 
          ).repeat(1)
        end

        def text_formatted
           (inline_chars? >> inline )
        end

        def text_any
          tl = (text_formatted |
                  text_unformatted.as(:text)
                ).repeat(2) | 
                text_formatted.repeat(1,1) | 
                text_unformatted
        end
      end
    end
  end
end
