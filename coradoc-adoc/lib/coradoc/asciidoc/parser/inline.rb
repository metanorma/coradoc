# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Inline
        def attribute_reference
          str('{').present? >> str('{') >>
            match('[a-zA-Z0-9_-]').repeat(1).as(:attribute_reference) >>
            str('}')
        end

        def bold_constrained
          (str('*').present? >> str('*') >>
            match('[^*\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('*') >> str('*').absent? >>
             str("\n\n").absent?
          ).as(:bold_constrained)
        end

        def bold_unconstrained
          (str('**').present? >> str('**') >>
            match('[^*\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('**')
          ).as(:bold_unconstrained)
        end

        def span_constrained
          (attribute_list >>
            str('#') >>
            match('[^#\n]').repeat(1).as(:text) >>
             str('#') >> str('#').absent?
          ).as(:span_constrained)
        end

        def span_unconstrained
          (attribute_list >>
            str('##') >>
            match('[^#\n]').repeat(1).as(:text) >>
             str('##')
          ).as(:span_unconstrained)
        end

        def italic_constrained
          (str('_') >> str('_').absent? >>
            match('[^_\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('_') >> str('_').absent?
          ).as(:italic_constrained)
        end

        def italic_unconstrained
          (str('__') >>
            match('[^_\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('__')
          ).as(:italic_unconstrained)
        end

        def highlight_constrained
          (str('#') >>
            match('[^#\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('#') >> str('#').absent?
          ).as(:highlight_constrained)
        end

        def highlight_unconstrained
          (str('##') >>
            match('[^#\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('##')
          ).as(:highlight_unconstrained)
        end

        def monospace_constrained
          (str('`') >>
            match('[^`\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('`') >> str('`').absent?
          ).as(:monospace_constrained)
        end

        def monospace_unconstrained
          (str('``') >>
            match('[^`\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('``')
          ).as(:monospace_unconstrained)
        end

        def superscript
          (str('^') >>
            match('[^^\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('^')
          ).as(:superscript)
        end

        def subscript
          (str('~') >>
            match('[^~\n]').repeat(1).as(:text).repeat(1, 1) >>
             str('~')
          ).as(:subscript)
        end

        def span
          attribute_list >>
            (str('#') >>
              match('[^#\n]').repeat(1).as(:text) >>
               str('#') >> str('#').absent?
            ).as(:span)
        end

        def link
          ((str('http').present? | str('https').present? | str('ftp').present?) >>
            match('[A-Za-z0-9_.\\-:/&?=+,%#~;]+').repeat(1).as(:path) >>
            (str('[') >> match('[^\\]]').repeat(1).as(:text) >> str(']')).maybe
          ).as(:link) |
            (str('link:').present? >> str('link:') >>
              match('[A-Za-z0-9_.\\-:/&?=+,%#~;]+').repeat(1).as(:path) >>
              (str('[') >> match('[^\\]]').repeat(1).as(:text) >> str(']')).maybe
            ).as(:link)
        end

        def inline_image
          (str('image:').present? >> str('image:') >>
            match('[A-Za-z0-9_.\\-:/&?=+,%#~;]+').repeat(1).as(:path) >>
            (str('[') >> match('[^\\]]').repeat(1).as(:text) >> str(']')).maybe
          ).as(:inline_image)
        end

        # Triple-plus inline passthrough: `+++raw content+++`. The content
        # passes through all substitutions verbatim. Common use is to embed
        # raw HTML in AsciiDoc documents.
        def inline_passthrough
          (str('+++') >>
            (str('+++').absent? >> match('[^\n]')).repeat(1).as(:raw) >>
            str('+++')
          ).as(:inline_passthrough)
        end

        def underline
          (attribute_list >> match('\\[.underline\\]').as(:role) >>
            str('#') >>
            match('[^#\n]').repeat(1).as(:text) >>
            str('#')
          ).as(:underline)
        end

        def small
          (attribute_list >> match('\\[.small\\]').as(:role) >>
            str('#') >>
            match('[^#\n]').repeat(1).as(:text) >>
            str('#')
          ).as(:small)
        end

        def inline_chars?
          match('[\[*#_{<^~`]').present? |
            str('http').present? |
            str('https').present? |
            str('link:').present? |
            str('image:').present? |
            str('+++').present? |
            term_type.present? |
            str('footnote').present? |
            stem_type.present? |
            str('\\<<').present?
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
            escaped_xref |
            cross_reference |
            term_inline |
            term_inline2 |
            footnote |
            stem |
            link |
            inline_image |
            inline_passthrough |
            underline |
            small
        end

        def text_unformatted
          # `str('\\<<').absent?` stops text from consuming the backslash of
          # an escaped xref (`\<<`). Without this guard, the `\` is taken as
          # plain text, the `<<` re-enters cross_reference, and the literal
          # escape is destroyed.
          (str('\\<<').absent? >>
            inline.absent? >>
            match("[^\n]")
          ).repeat(1)
        end

        def text_formatted
          (inline_chars? >> inline)
        end

        def text_any
          (text_formatted |
                  text_unformatted.as(:text)
          ).repeat(2) |
            text_formatted.repeat(1, 1) |
            text_unformatted
        end
      end
    end
  end
end
