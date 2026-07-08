# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Inline
        # Typographic quote patterns are owned by the shared
        # {Coradoc::AsciiDoc::TypographicQuotes} module so both the
        # parser and the transformer reference the same source of
        # truth without one layer reaching across the other.

        def typographic_quote
          patterns = AsciiDoc::TypographicQuotes::PATTERNS
          combined = patterns.reduce(nil) do |acc, pat|
            atom = str(pat)
            acc ? (acc | atom) : atom
          end
          combined.as(:typographic_quote)
        end

        def attribute_reference
          str('{').present? >> str('{') >>
            match('[a-zA-Z0-9_-]').repeat(1).as(:attribute_reference) >>
            str('}')
        end

        # ── Constrained / unconstrained mark builders ──
        #
        # Single source of truth for the four constrained + four
        # unconstrained inline mark rules. Before this extraction each
        # rule hand-rolled the same open → content → close → lookahead
        # shape with subtly different guards (presence checks, newline
        # exclusions, inner-marker allowances). Now each rule is a
        # 1-line wrapper over one of two parameterised builders.
        #
        # The constrained builder adds a `marker.absent?` guard on both
        # ends so single-marker constrained never matches when a
        # double-marker unconstrained is intended (e.g. `*` defers to
        # `**`). The alternation order in `inline` handles this too,
        # but the guard is belt-and-suspenders — it keeps each rule
        # self-contained for unit testing.
        #
        # The unconstrained builder allows newlines in the content
        # (Asciidoctor's behaviour for `__`, `**`, `##`, ``` `` ``` — a
        # mark can span line breaks). This was Bug 15B's fix scope;
        # highlight_unconstrained was previously inconsistent (excluded
        # newlines). All four are now uniform.

        def constrained_mark(marker, reject_paragraph_break: false, content: nil)
          open_guard = str(marker) >> str(marker).absent?
          content_rule = content || default_constrained_content(marker)
          close_guard = str(marker) >> str(marker).absent?
          sequence = open_guard >> content_rule >> close_guard
          sequence >>= str("\n\n").absent? if reject_paragraph_break
          sequence
        end

        def default_constrained_content(marker)
          match("[^#{marker}\n]").repeat(1).as(:text).repeat(1, 1)
        end

        def unconstrained_mark(marker)
          double = marker * 2
          str(double) >>
            match("[^#{marker}]").repeat(1).as(:text).repeat(1, 1) >>
            str(double)
        end

        def bold_constrained
          constrained_mark('*', reject_paragraph_break: true).as(:bold_constrained)
        end

        def bold_unconstrained
          unconstrained_mark('*').as(:bold_unconstrained)
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
          constrained_mark('_').as(:italic_constrained)
        end

        def italic_unconstrained
          unconstrained_mark('_').as(:italic_unconstrained)
        end

        def highlight_constrained
          constrained_mark('#').as(:highlight_constrained)
        end

        def highlight_unconstrained
          unconstrained_mark('#').as(:highlight_unconstrained)
        end

        def monospace_constrained
          content = constrained_span_content('`').as(:text).repeat(1, 1)
          constrained_mark('`', content: content).as(:monospace_constrained)
        end

        def monospace_unconstrained
          unconstrained_mark('`').as(:monospace_unconstrained)
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
            str(':').absent? >>
            match('[A-Za-z0-9_.\\-:/&?=+,%#~;]+').repeat(1).as(:path) >>
            attribute_list(:attribute_list).maybe
          ).as(:inline_image)
        end

        # Triple-plus inline passthrough: `+++raw content+++`. The content
        # passes through all substitutions verbatim. Common use is to embed
        # raw HTML in AsciiDoc documents.
        def inline_passthrough_triple_plus
          (str('+++') >>
            (str('+++').absent? >> match('[^\n]')).repeat(1).as(:raw) >>
            str('+++')
          ).as(:inline_passthrough)
        end

        # `pass:[raw]` macro form. Equivalent semantic to triple-plus:
        # the bracket payload survives all substitutions verbatim. Common
        # use is inside monospace spans to keep characters like `<` from
        # being re-interpreted as xref markers. The optional `subs` segment
        # (`pass:quotes[...]`) is consumed but currently ignored — the
        # payload is always passed through raw.
        def inline_passthrough_macro
          (str('pass:').present? >> str('pass:') >>
            match('[a-zA-Z,+]').repeat(0) >>
            str('[') >> (str(']]').absent? >> match('[^\]\n]')).repeat(1).as(:raw) >>
            str(']')
          ).as(:inline_passthrough)
        end

        def inline_passthrough
          inline_passthrough_triple_plus | inline_passthrough_macro
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
            typographic_quote.present? |
            str('http').present? |
            str('https').present? |
            str('link:').present? |
            str('image:').present? |
            str('+++').present? |
            str('pass:').present? |
            term_type.present? |
            str('footnote').present? |
            stem_type.present? |
            str('\\<<').present? |
            hard_line_break_marker?
        end

        # AsciiDoc hard line break: a space followed by `+` at end of line,
        # or a backslash at end of line. Both forms render as `<br>` inside
        # the enclosing paragraph/verse. Recognised ahead of `text_unformatted`
        # so the marker isn't swallowed as plain text.
        def hard_line_break_marker?
          (str(' +') >> str("\n")).present? |
            (str('\\') >> str("\n")).present?
        end

        def hard_line_break
          ((str(' +') >> str("\n")) |
             (str('\\') >> str("\n"))).as(:hard_line_break)
        end

        # Priority-ordered registry of inline rules. The ORDER IS LOAD-BEARING:
        # typographic_quote MUST come before monospace_constrained (Bug 14);
        # each unconstrained rule MUST come before its constrained sibling
        # (`` `` `` before `` ` ``, `**` before `*`, `__` before `_`).
        # Adding a new inline rule = appending one symbol here (OCP).
        INLINE_RULE_ORDER = %i[
          typographic_quote
          bold_unconstrained bold_constrained
          span_unconstrained span_constrained
          italic_unconstrained italic_constrained
          highlight_unconstrained highlight_constrained
          monospace_unconstrained monospace_constrained
          superscript subscript
          attribute_reference
          escaped_xref cross_reference
          term_inline term_inline2
          footnote stem
          link inline_image
          inline_passthrough
          underline small
          hard_line_break
        ].freeze

        def inline
          INLINE_RULE_ORDER.map { |name| public_send(name) }.reduce(:|)
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

        # Content model for a constrained inline span (`` `…` ``, `*…*`,
        # `_…_`, `#…#`). Allows the corresponding unconstrained marker
        # pair (`` `` ``, `**`, `__`, `##`) to appear inside the content
        # rather than terminating the span at the first marker character.
        #
        # Asciidoctor treats the contents of a constrained span as an
        # inline literal — nested constrained markers do not close the
        # span. Without this allowance, `` `<<\`\`x\`\`>>` `` fails to
        # match as a single monospace span: the parser sees the inner
        # `` `` `` as a failed single-backtick close attempt, backtracks
        # out of `monospace_constrained`, and the `<<…>>` payload then
        # fires the `cross_reference` rule with the backticks glued
        # onto the target.
        #
        # Single source of truth for every constrained rule's content
        # model — adding a new constrained marker reuses this helper
        # rather than re-spelling the alternation (DRY).
        def constrained_span_content(marker)
          (match("[^#{marker}\n]") | str(marker * 2)).repeat(1)
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
