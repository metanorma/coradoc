# frozen_string_literal: true

require_relative 'parslet_extras'

module Coradoc
  module Markdown
    module Parser
      class BlockParser < Parslet::Parser
        using ParsletExtras

        # NOTE: Debug method for parser development. Outputs current parse position
        # and capture context. Only called during parser debugging sessions.
        def debug(msg)
          dynamic do |src, ctx|
            puts "#{msg} @ #{src.line_and_column}:"
            pp ctx.captures
            any.present? | any.absent?
          end
        end

        rule(:line_ending) { (str("\n") | str("\r\n") | str("\r")).ignore }
        rule(:line_ending_or_eof) { line_ending | any.absent? }

        rule(:whitespace) { match[" \t"] }
        # NOTE: repeat(1) before EOF (any.absent?) because infinite loop otherwise
        rule(:blank_line) { (whitespace.repeat(1) >> any.absent? | whitespace.repeat >> line_ending).ignore }
        rule(:blank_line_verbatim) do
          whitespace.repeat(1).as(:ln) >> any.absent? | whitespace.repeat.as(:ln) >> line_ending
        end
        rule(:line_char) { match["^\r\n"] }
        rule(:line_verbatim) { line_char.repeat(1).as(:ln) >> line_ending_or_eof }

        rule(:non_indent_space) { str(' ').repeat(0, 3) }

        # Block nesting is the tricky part, but Parslet's `dynamic` and `scope`
        # make it possible to be aware of what blocks we're already in, and implement
        # a check for whether we're still inside of those blocks on the beginning of
        # every line. The rules that match the line run inside of the innermost
        # parser expression, but this way they are aware of where they're nested at runtime.
        #
        # `continuation` MUST NOT be a `rule`, otherwise gets cached in a failure state
        # and prevents nested alternatives from working
        def continuation
          dynamic do |_src, ctx|
            # puts "parsing continuation at #{src.line_and_column} (#{src.bytepos}) with #{ctx.captures[:cont]}"
            if ctx.captures.key?(:cont)
              ctx.captures[:cont].ignore
            else
              any.present?
            end
          end
        end

        def open_block(kind, cont_rule)
          dynamic do |_src, ctx|
            parent_scope = ctx.captures.current.parent
            ctx.captures[:cont] = cont_rule
            ctx.captures[:cont] = parent_scope[:cont] >> cont_rule if parent_scope.key?(:cont)
            ctx.captures[:block] = kind
            # puts "starting block #{kind} at #{src.line_and_column} (#{src.bytepos}): #{ctx.captures[:cont]}"
            any.present? | any.absent?
          end
        end

        rule(:atx_ending_seq) do
          whitespace.repeat(1) >>
            str('#').repeat >>
            whitespace.repeat >>
            (line_ending.present? | any.absent?)
        end

        # Escaped hash - not a heading
        rule(:escaped_hash) do
          str('\\') >> str('#')
        end

        rule(:atx_heading) do
          non_indent_space >>
            escaped_hash.absent? >>
            str('#').repeat(1, 6).as(:heading) >>
            str('#').absent? >>
            (
              # first, check to catch the case with only one space
              # (that would be consumed with the repeat(1)) until ending seq
              atx_ending_seq.absent? >>
              str(' ').repeat(1) >>
              (
                atx_ending_seq.absent? >> line_char
              ).repeat(1).as(:text)
            ).maybe >>
            atx_ending_seq.maybe >>
            line_ending_or_eof
        end

        def thematic_break_char(c)
          (str(c) >> whitespace.repeat).repeat(3)
        end

        rule(:thematic_break) do
          non_indent_space >>
            (
              thematic_break_char('-') | thematic_break_char('_') | thematic_break_char('*')
            ).output(hr: true) >>
            line_ending_or_eof
        end

        rule(:indented_code_line) do
          str('    ') >> line_verbatim
        end

        rule(:indented_code_blank_line) do
          blank_line_verbatim.output(ln: '') >>
            (
              continuation >>
              (str('    ') | blank_line_verbatim)
            ).present?
        end

        rule(:indented_code_block) do
          (
            indented_code_line >>
            (
              continuation >>
              (indented_code_line | indented_code_blank_line)
            ).repeat
          ).as(:code_block)
        end

        def code_fence_info
          # NOTE: Uses dynamic block for context-dependent fence character detection
          # This handles both backtick (`) and tilde (~) fenced code blocks
          dynamic do |_src, ctx|
            char = line_char
            char = str('`').absent? >> char if ctx.captures[:fence].to_s.chr == '`'
            char.repeat(1).as(:info).maybe
          end
        end

        rule(:code_fence_open) do
          non_indent_space.capture(:fence_indent) >>
            (str('`').repeat(3) | str('~').repeat(3)).capture(:fence).ignore >>
            code_fence_info >>
            line_ending_or_eof
        end

        rule(:code_fence_close) do
          non_indent_space >> dynamic do |_src, ctx|
            str(ctx.captures[:fence]) >>
              str(ctx.captures[:fence].to_s.chr).repeat
          end.ignore >> line_ending_or_eof
        end

        def consume_fenced_indent
          dynamic do |_src, ctx|
            indent = ctx.captures[:fence_indent].to_s.length
            if indent.positive?
              str(' ').repeat(0, indent)
            else
              any.present?
            end
          end
        end

        rule(:fenced_code_block) do
          code_fence_open >>
            (
              continuation >>
              code_fence_close.absent? >>
              consume_fenced_indent >>
              (line_verbatim | blank_line_verbatim.output(ln: ''))
            ).repeat.as(:code_block) >>
            (
              (continuation >> code_fence_close) | continuation.absent? | any.absent?
            )
        end

        rule(:block_quote_marker) do
          non_indent_space >>
            str('>') >>
            str(' ').maybe
        end

        # This implements laziness, which is context-sensitive:
        # "only applies to lines that would have been continuations of
        # paragraphs had they been prepended with block quote markers"
        # means we *actually* must be inside of a continueable paragraph.
        #
        # Cannot be a `rule` as usual with `dynamic`.
        def block_quote_cont
          dynamic do |_src, ctx|
            # puts "BQDYN in #{ctx.captures[:block]}"
            block_quote_marker | if ctx.captures[:block] == :paragraph
                                   paragraph_interrupt.absent? >> paragraph_continued_line.present?
                                 else
                                   any.absent? >> any.present? # never match
                                 end
          end
        end

        rule(:block_quote) do
          block_quote_marker >> scope do
            open_block(:block_quote, block_quote_cont) >>
              (
                (block | any.absent?.output('')) >>
                (
                  continuation >>
                  (block | any.absent?.output(''))
                ).repeat
              ).as(:block_quote)
          end
        end

        # IAL that appears on its own line (applies to next block or as ALD)
        rule(:ial_block) do
          whitespace.repeat(0, 3) >> (ial | ald) >> line_ending_or_eof
        end

        rule(:paragraph_interrupt) do
          blank_line | atx_heading | thematic_break |
            code_fence_open | block_quote | ial_block | extension |
            unordered_list_marker | ordered_list_marker | definition_marker
        end

        rule(:paragraph_line) do
          line_char.repeat(1).as(:ln) >> any.absent? | line_char.repeat.as(:ln) >> line_ending
        end

        rule(:paragraph_continued_line) do
          whitespace.repeat.ignore >>
            paragraph_line
        end

        rule(:paragraph) do
          # Tempting to not use `scope` here as `paragraph` is a leaf block,
          # but laziness rules for block quotes and lists need to know
          # whether we are actually in a paragraph that could be continued
          non_indent_space >> scope do
            open_block(:paragraph, paragraph_interrupt.absent?) >>
              (
                paragraph_line >>
                (
                  continuation >>
                  paragraph_continued_line
                ).repeat
              ).as(:p)
          end
        end

        rule(:setext_underline) do
          non_indent_space >>
            (
              str('-').repeat(1) | str('=').repeat(1)
            ).as(:heading) >>
            whitespace.repeat.ignore >>
            line_ending_or_eof
        end

        rule(:setext_heading) do
          check = paragraph_interrupt.absent? >> setext_underline.absent?
          check >>
            non_indent_space >>
            (
              paragraph_line >>
              (
                continuation >>
                check >>
                paragraph_continued_line
              ).repeat
            ).as(:text) >>
            continuation >>
            setext_underline
        end

        # ===== KRAMDOWN EXTENSIONS =====

        # Inline Attribute List (IAL): {:.class #id key="value"}
        # Can appear after any block element to add attributes
        rule(:ial_class) do
          str('.') >> match['\\w\\-'].repeat(1)
        end

        rule(:ial_id) do
          str('#') >> match['\\w\\-'].repeat(1)
        end

        rule(:ial_key_value) do
          match['\\w\\-'].repeat(1) >> str('=') >>
            (
              str('"') >> match['^"'].repeat(0) >> str('"') |
              str("'") >> match["^'"].repeat(0) >> str("'") |
              match['^\\s\\}'].repeat(1)
            )
        end

        rule(:ial_content) do
          (
            whitespace.repeat >>
            (ial_class | ial_id | ial_key_value)
          ).repeat(1)
        end

        rule(:ial) do
          str('{:') >> ial_content.as(:ial) >> str('}')
        end

        # Attribute List Definition (ALD): {:name: #id .class key="value"}
        # Defines a named attribute list that can be referenced
        rule(:ald_name) do
          match['\\w'].repeat(1) >> str(':')
        end

        rule(:ald) do
          str('{:') >> ald_name.as(:ald_name) >> whitespace.repeat(1) >> ial_content.as(:ial) >> str('}')
        end

        # Block-level extension: {::extension_name options /}
        # Common extensions: {::toc}, {::options ... /}
        rule(:extension_name) do
          match['a-z'].repeat(1)
        end

        rule(:extension_option) do
          match['\\w\\-'].repeat(1) >> str('=') >>
            (
              str('"') >> match['^"'].repeat(0) >> str('"') |
              str("'") >> match["^'"].repeat(0) >> str("'") |
              match['^\\s/\\}'].repeat(1)
            )
        end

        rule(:extension_options) do
          (whitespace.repeat(1) >> extension_option).repeat
        end

        rule(:extension_self_closing) do
          str('{::') >> extension_name.as(:ext_name) >> extension_options.as(:ext_options) >> whitespace.repeat >> str('/}')
        end

        rule(:extension_with_body) do
          str('{::') >> extension_name.as(:ext_name) >> extension_options.as(:ext_options) >> str('}') >>
            (str('{:/').absent? >> any).repeat.as(:ext_body) >>
            str('{:/}')
        end

        rule(:extension) do
          (extension_self_closing | extension_with_body).as(:extension)
        end

        # Block math: $$...$$ on its own line(s)
        rule(:block_math) do
          str('$$') >> line_ending >>
            (str('$$').absent? >> any).repeat.as(:math_content) >>
            str('$$')
        end

        # ===== GFM TABLE PARSING RULES =====

        # Table cell: any characters except | and newline
        rule(:table_cell) do
          (str('|').absent? >> line_char).repeat.as(:cell)
        end

        # Table row: handles both | cell | cell | and cell | cell formats
        # Pattern: optional leading pipe, then (cell pipe)+ cell, optional trailing pipe
        # Or: cell | cell without any leading/trailing pipes
        rule(:table_row) do
          # Format with leading pipe: | cell | cell | or | cell | cell
          (str('|') >> whitespace.maybe >>
           (
             table_cell >>
             whitespace.maybe >>
             str('|') >>
             whitespace.maybe
           ).repeat(1).as(:row)) |
            # Format without leading pipe: cell | cell | or cell | cell
            (table_cell >>
             whitespace.maybe >>
             str('|') >>
             whitespace.maybe >>
             (
               table_cell >>
               whitespace.maybe >>
               str('|') >>
               whitespace.maybe
             ).repeat.as(:row_rest) >>
             table_cell.maybe.as(:last_cell)).as(:row)
        end

        # Table separator cell: dashes with optional colons
        rule(:table_separator_cell) do
          str(':').maybe >>
            str('-').repeat(1) >>
            str(':').maybe
        end

        # Separator row: handles both |---|---| and ---|---| formats
        rule(:table_separator_row) do
          # Format with leading pipe: |---|---| or |---|---|
          (str('|') >> whitespace.maybe >>
           (
             table_separator_cell.as(:sep) >>
             whitespace.maybe >>
             str('|') >>
             whitespace.maybe
           ).repeat(1)) |
            # Format without leading pipe: ---|---| or ---|---|
            (table_separator_cell.as(:sep) >>
             whitespace.maybe >>
             str('|') >>
             whitespace.maybe >>
             (
               table_separator_cell.as(:sep) >>
               whitespace.maybe >>
               str('|') >>
               whitespace.maybe
             ).repeat >>
             table_separator_cell.as(:sep).maybe)
        end

        # GFM Table: header row, separator row, body rows
        rule(:table) do
          table_row.as(:table_header) >>
            line_ending >>
            table_separator_row.as(:table_separator) >>
            line_ending >>
            (
              table_row.as(:table_body_row) >> line_ending
            ).repeat(1).as(:table_body)
        end

        rule(:block) do
          blank_line | eob_marker | atx_heading | thematic_break |
            indented_code_block | fenced_code_block |
            block_quote | setext_heading |
            unordered_list | ordered_list | definition_list |
            footnote_definition | abbreviation_definition |
            ial_block | extension | block_math |
            table | paragraph
        end

        # ===== LIST PARSING RULES =====

        # List interrupt - blocks that can interrupt a list
        rule(:list_interrupt) do
          blank_line.repeat(1) | atx_heading | thematic_break |
            code_fence_open | block_quote |
            unordered_list_marker | ordered_list_marker
        end

        # Unordered list marker: -, *, or + followed by 1+ spaces
        rule(:unordered_list_marker) do
          non_indent_space >>
            match['-*+'] >>
            str(' ').repeat(1)
        end

        # Ordered list marker: 1-9 digits followed by . or ) and 1+ spaces
        rule(:ordered_list_marker) do
          non_indent_space >>
            match['1-9'] >>
            match['0-9'].repeat >>
            match['\\.)'] >>
            str(' ').repeat(1)
        end

        # List item continuation line (indented content that's not a block)
        # Excludes lines that look like nested list markers
        rule(:list_continuation_line) do
          (str('    ') | str("\t")) >>
            nested_list_marker.absent? >>
            line_verbatim |
            nested_list_marker.absent? >>
            line_verbatim
        end

        # Nested list marker detection (for 4-space indented lists)
        rule(:nested_list_marker) do
          (str('    ') | str("\t")) >>
            (
              (match['-*+'] >> str(' ').repeat(1)) |
              (match['1-9'] >> match['0-9'].repeat >> match['\\.)'] >> str(' ').repeat(1))
            )
        end

        # Thematic break as list item content (e.g., "- * * *")
        rule(:thematic_break_in_list) do
          (
            (str('*') >> whitespace.repeat >> str('*') >> whitespace.repeat >> str('*')) |
            (str('-') >> whitespace.repeat >> str('-') >> whitespace.repeat >> str('-')) |
            (str('_') >> whitespace.repeat >> str('_') >> whitespace.repeat >> str('_'))
          ) >> whitespace.repeat >> line_ending_or_eof
        end

        # Unordered list item with content
        # Can contain thematic break or paragraph with continuation lines
        rule(:unordered_list_item) do
          unordered_list_marker.capture(:list_marker) >>
            (
              thematic_break_in_list.output(hr: true).as(:li) |
              list_item_content.as(:li)
            )
        end

        # List item content - paragraph first, then optional nested blocks
        rule(:list_item_content) do
          list_item_paragraph >>
            (
              continuation >>
              list_interrupt.absent? >>
              nested_block
            ).repeat
        end

        # Nested block (indented list, etc.)
        rule(:nested_block) do
          (str('    ') | str("\t")) >> nested_unordered_list |
            (str('    ') | str("\t")) >> nested_ordered_list
        end

        # Nested unordered list (4-space indented)
        rule(:nested_unordered_list) do
          (
            nested_unordered_list_item >>
            (
              continuation >>
              (str('    ') | str("\t")) >>
              nested_unordered_list_item
            ).repeat
          ).as(:ul)
        end

        # Nested unordered list item (simpler format - just text content)
        rule(:nested_unordered_list_item) do
          unordered_list_marker >> line_verbatim
        end

        # Nested ordered list (4-space indented)
        rule(:nested_ordered_list) do
          (
            nested_ordered_list_item >>
            (
              continuation >>
              (str('    ') | str("\t")) >>
              nested_ordered_list_item
            ).repeat
          ).as(:ol)
        end

        # Nested unordered list item (simpler format - just text content)
        rule(:nested_unordered_list_item) do
          unordered_list_marker >> line_text.as(:li)
        end

        # Line text without the :ln wrapper
        rule(:line_text) do
          line_char.repeat(1) >> line_ending_or_eof
        end

        # Nested ordered list item (simpler format - just text content)
        rule(:nested_ordered_list_item) do
          ordered_list_marker >> line_text.as(:li)
        end

        # List item paragraph - first line plus any continuation lines
        rule(:list_item_paragraph) do
          (
            line_verbatim >>
            (
              continuation >>
              list_interrupt.absent? >>
              nested_list_marker.absent? >>
              list_continuation_line
            ).repeat
          ).as(:p)
        end

        # Ordered list item with content (wraps content in p structure)
        rule(:ordered_list_item) do
          ordered_list_marker >>
            list_item_content.as(:li)
        end

        # Unordered list: sequence of items (thematic break interrupts)
        rule(:unordered_list) do
          (
            unordered_list_item >>
            (
              continuation >>
              thematic_break.absent? >>
              blank_line.maybe >>
              unordered_list_item
            ).repeat
          ).as(:ul)
        end

        # Ordered list: sequence of numbered items (thematic break interrupts)
        rule(:ordered_list) do
          (
            ordered_list_item >>
            (
              continuation >>
              thematic_break.absent? >>
              blank_line.maybe >>
              ordered_list_item
            ).repeat
          ).as(:ol)
        end

        # ===== KRAMDOWN DEFINITION LIST PARSING RULES =====

        # Definition list marker: colon followed by space
        rule(:definition_marker) do
          non_indent_space >>
            str(':') >>
            str(' ').repeat(1)
        end

        # Definition term: line(s) not starting with colon
        # Can span multiple lines if next line doesn't start with :
        rule(:definition_term_line) do
          non_indent_space >>
            str(':').absent? >>
            line_verbatim
        end

        # Definition term with continuation
        rule(:definition_term) do
          (
            definition_term_line >>
            (
              continuation >>
              definition_marker.absent? >>
              blank_line.absent? >>
              definition_term_line
            ).repeat
          ).as(:def_term)
        end

        # Definition item content (after the :)
        rule(:definition_content) do
          (
            line_verbatim >>
            (
              continuation >>
              definition_marker.absent? >>
              blank_line.absent? >>
              (str(' ') | str("\t")).maybe >>
              line_verbatim
            ).repeat
          ).as(:def_content)
        end

        # Definition item: : followed by content
        rule(:definition_item) do
          definition_marker >> definition_content
        end

        # Definition list item: term followed by one or more definitions
        rule(:definition_list_item) do
          definition_term >>
            (
              continuation >>
              definition_item
            ).repeat(1)
        end

        # Definition list: sequence of term+definition groups
        rule(:definition_list) do
          (
            definition_list_item >>
            (
              continuation >>
              blank_line.maybe >>
              definition_list_item
            ).repeat
          ).as(:dl)
        end

        # ===== KRAMDOWN FOOTNOTE PARSING RULES =====

        # Footnote definition: [^name]: content
        rule(:footnote_id) do
          str('[^') >> match['^\]'].repeat(1).as(:fn_id) >> str(']')
        end

        rule(:footnote_definition) do
          non_indent_space >>
            footnote_id >>
            str(':') >>
            whitespace.repeat >>
            line_verbatim.as(:fn_content) >>
            (
              continuation >>
              (str(' ') | str("\t")).repeat(1, 4) >>
              line_verbatim
            ).repeat.as(:fn_content_continued)
        end

        # ===== KRAMDOWN ABBREVIATION PARSING RULES =====

        # Abbreviation definition: *[TERM]: definition
        rule(:abbreviation_term) do
          str('*[') >> match['^\]'].repeat(1).as(:abbr_term) >> str(']')
        end

        rule(:abbreviation_definition) do
          non_indent_space >>
            abbreviation_term >>
            str(':') >>
            whitespace.repeat >>
            line_char.repeat.as(:abbr_def) >>
            line_ending_or_eof
        end

        # ===== KRAMDOWN EOB (End of Block) MARKER =====

        # EOB marker: ^ on its own line (terminates blocks explicitly)
        rule(:eob_marker) do
          whitespace.repeat >> str('^') >> whitespace.repeat >> line_ending_or_eof
        end

        root :document
        rule(:document) do
          block.repeat
        end

        def self.parse(filename)
          content = File.read(filename)
          new.parse(content)
        rescue Parslet::ParseFailed => e
          puts e.parse_failure_cause.ascii_tree
        end

        # Parse with AST post-processing (escape sequences, etc.)
        def self.parse_with_processing(content)
          ast = new.parse(content)
          AstProcessor.process(ast)
        rescue Parslet::ParseFailed => e
          puts e.parse_failure_cause.ascii_tree
          nil
        end
      end
    end
  end
end
