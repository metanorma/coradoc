# frozen_string_literal: true

# $DEBUG = true
module Coradoc
  module AsciiDoc
    module Parser
      module List
        def list(nesting_level = 1)
          (
          unordered_list(nesting_level) |
             ordered_list(nesting_level) |
             definition_list
        ).as(:list)
        end

        def list_continuation
          line_start? >> str("+\n")
        end

        def ordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = olist_item(nesting_level)
          attrs >> (empty_line.repeat(0) >> r).repeat(1).as(:ordered)
        end

        def unordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = ulist_item(nesting_level)
          attrs >> (empty_line.repeat(0) >> r).repeat(1).as(:unordered)
        end

        def definition_list(_delimiter = nil)
          (attribute_list >> newline).maybe >>
            dlist_item.repeat(1).as(:definition_list) >>
            dlist_item.absent?
        end

        def list_marker(nesting_level = 1)
          olist_marker(nesting_level) | ulist_marker(nesting_level)
        end

        def olist_marker(nesting_level = 1)
          # Don't match table cell format specs like ".2+^.^|"
          line_start? >>
            (nesting_level > 1 ? literal_space.maybe : str('')) >>
            str('.' * nesting_level) >>
            str('.').absent? >>
            (
              (match['0-9.<>^'] | str('+')).repeat(0, 3) >> str('|')
            ).absent?
        end

        def olist_item(nesting_level = 1)
          item = olist_marker(nesting_level).as(:marker) >>
                 match("\n").absent? >> space >>
                 (list_body_text_line >>
                  list_item_continuation_lines).as(:lines)

          att = (list_continuation.present? >>
                  list_continuation >>
                  (admonition_line | paragraph | block)
                ).repeat(0).as(:attached)
          item >>= att.maybe

          if nesting_level <= 4
            item >>= (list_marker(nesting_level + 1).present? >>
                   list(nesting_level + 1)).repeat(0).as(:nested)
          end
          olist_marker(nesting_level).present? >> item.as(:list_item)
        end

        def ulist_marker(nesting_level = 1)
          line_start? >>
            (nesting_level > 1 ? literal_space.maybe : str('')) >>
            (
              asterisk_marker(nesting_level) |
              dash_marker(nesting_level)
            )
        end

        # AsciiDoc standard bullet: `*`, `**`, `***`, ... matching the
        # nesting level. Excludes table delimiters (`|===`) and deeper
        # asterisk runs that belong to a sibling level.
        def asterisk_marker(nesting_level)
          str('*' * nesting_level) >>
            str('*').absent? >>
            str('===').absent?
        end

        # Markdown-style dash bullet: `-`. Accepted only at the top level
        # because Markdown nests via indentation rather than multi-char
        # markers — deeper levels stay on the AsciiDoc `*` form. Guards
        # exclude em-dashes (`--`), delimited-block fences (`----`),
        # and negative-number runs (`-1`, `-42`) which are not list
        # markers in any common dialect.
        def dash_marker(nesting_level)
          return match('').absent? unless nesting_level == 1

          str('-') >>
            str('-').absent? >>
            match('[0-9]').absent?
        end

        def ulist_item(nesting_level = 1)
          item = ulist_marker(nesting_level).as(:marker) >>
                 str(' [[[').absent? >>
                 match("\n").absent? >> space >>
                 (list_body_text_line >>
                  list_item_continuation_lines).as(:lines)

          att = (list_continuation.present? >>
                  list_continuation >>
                  (admonition_line | paragraph | block)
                ).repeat(0).as(:attached)
          item >>= att.maybe

          if nesting_level <= 4
            item >>= (list_marker(nesting_level + 1).present? >>
                   list(nesting_level + 1)).repeat(0).as(:nested)
          end
          ulist_marker(nesting_level).present? >> item.as(:list_item)
        end

        # Continuation lines of a list item's first paragraph. AsciiDoc
        # joins consecutive non-blank lines into one paragraph within the
        # item, but the lines must not start a sibling construct (another
        # list marker, block delimiter, attribute list, section, element
        # id, table boundary, list continuation, or list prefix).
        # `line_not_text?` (from Paragraph) is that exact lookahead.
        #
        # Uses `list_body_text_line` (not raw `text_line`) so a hard break
        # at end of one source line doesn't greedy-pull the next line's
        # content via text_any — same fix as dlist.
        def list_item_continuation_lines
          (line_not_text? >> list_body_text_line).repeat(0)
        end

        def dlist_delimiter
          (
            (str(':::::') >> match(':').absent?) |
            (str('::::') >> match(':').absent?) |
            (str(':::') >> match(':').absent?) |
            (str('::') >> match(':').absent?) |
            str(';;')
          ).as(:delimiter)
        end

        def dlist_term(_delimiter = nil)
          term_chars =
            (dlist_delimiter.absent? >> match("[^\n]")).repeat(1)
                                                       .as(:text)
          (element_id_inline.maybe >> term_chars).as(:dlist_term) >> dlist_delimiter
        end

        def dlist_definition
          # AsciiDoc convention: the definition body is indented relative
          # to the term. That leading whitespace is structural (marks
          # the line as a continuation of the dlist item), not content.
          # Consume it without capturing so downstream CoreModel text
          # doesn't carry the source indentation into HTML/Markdown.
          #
          # Multi-line definitions: AsciiDoc joins consecutive non-blank
          # lines into a single paragraph within the dd. We capture each
          # source line so the transformer can join them.
          #
          # Two load-bearing guards:
          #   1. `line_not_text?` — prevents matching a `+` (list
          #      continuation marker) or `[example]` (block attribute)
          #      as the dd's text content.
          #   2. `dlist_definition_line` (custom text_line variant) —
          #      text_line's text_any is greedy and matches across
          #      newlines via hard_line_break, swallowing the next
          #      source line's content (e.g. the `+` marker on the
          #      line after a hard break). The custom matcher excludes
          #      hard_line_break from the inline set so each `:lines`
          #      entry corresponds to exactly one source line.
          (line_not_text? >> match('[ \t]').repeat(0) >>
            (list_body_text_line >> list_item_continuation_lines).as(:lines)
          ) >> empty_line.repeat(0)
        end

        # Single source line of text for any list item body (dlist dd,
        # ulist item, olist item). Like text_line(false, unguarded: true)
        # but uses `LIST_BODY_INLINE_RULE_NAMES` (excludes hard_line_break)
        # so hard_break's ` +\n` consumption doesn't greedy-pull the next
        # source line's content (e.g. the `+` line-continuation marker).
        #
        # Shared across list types — single source of truth for the
        # "text inside a list item" grammar.
        def list_body_text_line
          literal_space? >>
            list_body_text_any.as(:text) >>
            list_body_line_ending
        end

        def list_body_text_any
          (list_body_inline_except_hard_break |
            list_body_text_unformatted.as(:text)).repeat(1)
        end

        def list_body_inline_except_hard_break
          LIST_BODY_INLINE_RULE_NAMES.map { |name| public_send(name) }.reduce(:|)
        end

        # Single source of truth for "inline rules usable inside a list
        # item body line". Mirrors INLINE_RULE_ORDER minus hard_line_break.
        # If INLINE_RULE_ORDER changes, update this list (the
        # list_body_inline_rule_names spec catches drift).
        LIST_BODY_INLINE_RULE_NAMES = %i[
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
        ].freeze

        def list_body_text_unformatted
          (str('\\<<').absent? >>
            list_body_inline_except_hard_break.absent? >>
            list_body_hard_break_marker?.absent? >>
            match("[^\n]")
          ).repeat(1)
        end

        def list_body_hard_break_marker?
          (str(' +') >> str("\n")).present? |
            (str('\\') >> str("\n")).present?
        end

        # Recognizes line endings for a list body source line, including
        # the ` +\n` hard-break form. The hard_break marker is preserved
        # as a `:hard_line_break` capture so downstream can render it
        # as `<br>`.
        def list_body_line_ending
          (str(' +').as(:hard_line_break) >> line_ending.as(:line_break)) |
            line_ending.as(:line_break) |
            eof?
        end

        def dlist_item(_delimiter = nil)
          # AST shape: { terms: [single dlist_term], delimiter: <delim>,
          #              lines: <def or nil>, attached: [...] }
          #
          # ONE term per dlist_item. Multi-term `<dt>`'s and multi-level
          # nesting are both handled by the transformer's `build_dlist_tree`,
          # which inspects each item's `delimiter` to infer depth and
          # merges consecutive same-depth term-only items into multi-term
          # items. Keeping the parser's term-emission at one-per-item lets
          # `delimiter` carry the nesting signal unambiguously — a parser
          # that greedily groups `parent::` and `child:::` into one item
          # loses the depth change between them.
          #
          # `repeat(1, 1).as(:terms)` ensures `:terms` is captured as a
          # single-element Array (matching the shape transformer's `Array()`
          # wrap expects) rather than a bare Hash — bare Hashes confuse
          # `Array(hash)` into nested-pair conversion.
          #
          # Two forms:
          #   1. multi-line: term on its own line, optional def on next line(s)
          #   2. inline:     term + def on same line
          multi_line = dlist_term.repeat(1, 1).as(:terms) >> line_ending >>
                       empty_line.repeat(0) >> dlist_definition.maybe
          inline = dlist_term.repeat(1, 1).as(:terms) >> space >> dlist_definition

          item = multi_line | inline

          attached = (list_continuation.present? >>
                       list_continuation >>
                       (admonition_line | paragraph | block)
                     ).repeat(0).as(:attached)
          item >>= attached.maybe

          item.as(:definition_list_item)
        end
      end
    end
  end
end
