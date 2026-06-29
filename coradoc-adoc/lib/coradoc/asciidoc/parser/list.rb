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
                 (text_line(false, unguarded: true) >>
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
                 (text_line(false, unguarded: true) >>
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
        # Each iteration matches exactly one source line via
        # `text_line(false, ...)` (single-newline termination). The
        # `.repeat(0)` walks multiple continuation lines one at a time.
        # Using `text_line(true, ...)` here would let `line_ending.repeat(1)`
        # greedy-match across blank lines, silently absorbing the
        # follow-up paragraph into the last list item's content.
        def list_item_continuation_lines
          (line_not_text? >> text_line(false, unguarded: true)).repeat(0)
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
          (match('[ \t]').repeat(0) >> text.as(:definition)) >>
            line_ending >> empty_line.repeat(0)
        end

        def dlist_item(_delimiter = nil)
          # Both forms below produce the same AST shape:
          #   {terms: [<dlist_term>, ...], definition: <text>}
          # so the transformer's definition_list_item rule matches uniformly.
          #
          # Multi-line form: one or more term-lines (`term::` + newline +
          # optional blank lines), then the definition on its own line(s).
          # Single-line form: one term + inline space + definition.
          term_line = dlist_term >> line_ending >> empty_line.repeat(0)

          ((term_line.repeat(1).as(:terms) >> dlist_definition) |
           (dlist_term.repeat(1, 1).as(:terms) >> space >>
             dlist_definition)).as(:definition_list_item)
        end
      end
    end
  end
end
