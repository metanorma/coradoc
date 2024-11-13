require_relative "parslet_extras"

module Coradoc
  module Parser
    module Markdown
      class BlockParser < Parslet::Parser
        using ParsletExtras

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
        rule(:blank_line_verbatim) { whitespace.repeat(1).as(:ln) >> any.absent? | whitespace.repeat.as(:ln) >> line_ending }
        rule(:line_char) { match["^\r\n"] }
        rule(:line_verbatim) { line_char.repeat(1).as(:ln) >> line_ending_or_eof }

        rule(:non_indent_space) { str(" ").repeat(0, 3) }

        # Block nesting is the tricky part, but Parslet's `dynamic` and `scope`
        # make it possible to be aware of what blocks we're already in, and implement
        # a check for whether we're still inside of those blocks on the beginning of
        # every line. The rules that match the line run inside of the innermost
        # parser expression, but this way they are aware of where they're nested at runtime.
        #
        # `continuation` MUST NOT be a `rule`, otherwise gets cached in a failure state
        # and prevents nested alternatives from working
        def continuation
          dynamic do |src, ctx|
            # puts "parsing continuation at #{src.line_and_column} (#{src.bytepos}) with #{ctx.captures[:cont]}"
            if ctx.captures.has_key?(:cont)
              ctx.captures[:cont].ignore
            else
              any.present?
            end
          end
        end

        def open_block(kind, cont_rule)
          dynamic do |src, ctx|
            parent_scope = ctx.captures.current.parent
            ctx.captures[:cont] = cont_rule
            ctx.captures[:cont] = parent_scope[:cont] >> cont_rule if parent_scope.has_key?(:cont)
            ctx.captures[:block] = kind
            # puts "starting block #{kind} at #{src.line_and_column} (#{src.bytepos}): #{ctx.captures[:cont]}"
            any.present? | any.absent?
          end
        end


        rule(:atx_ending_seq) do
          whitespace.repeat(1) >>
          str("#").repeat >>
          whitespace.repeat >>
          (line_ending.present? | any.absent?)
        end

        rule(:atx_heading) do
          non_indent_space >>
          str("#").repeat(1, 6).as(:heading) >>
          str("#").absent? >>
          (
            # first, check to catch the case with only one space
            # (that would be consumed with the repeat(1)) until ending seq
            atx_ending_seq.absent? >>
            str(" ").repeat(1) >>
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
            thematic_break_char("-") | thematic_break_char("_") | thematic_break_char("*")
          ).output(hr: true) >>
          line_ending_or_eof
        end

        rule(:indented_code_line) do
          str("    ") >> line_verbatim
        end

        rule(:indented_code_blank_line) do
          blank_line_verbatim.output(ln: "") >>
          (
            continuation >>
            (str("    ") | blank_line_verbatim)
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
          # TODO: make this less dynamic for speed, only 2 variations here
          dynamic do |src, ctx|
            char = line_char
            char = str("`").absent? >> char if ctx.captures[:fence].to_s.chr == "`"
            char.repeat(1).as(:info).maybe
          end
        end

        rule(:code_fence_open) do
          non_indent_space.capture(:fence_indent) >>
          (str("`").repeat(3) | str("~").repeat(3)).capture(:fence).ignore >>
          code_fence_info >>
          line_ending_or_eof
        end

        rule(:code_fence_close) do
          non_indent_space >> dynamic do |src, ctx|
            str(ctx.captures[:fence]) >>
            str(ctx.captures[:fence].to_s.chr).repeat
          end.ignore >> line_ending_or_eof
        end

        def consume_fenced_indent
          dynamic do |src, ctx|
            indent = ctx.captures[:fence_indent].to_s.length
            if indent > 0
              str(" ").repeat(0, indent)
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
            (line_verbatim | blank_line_verbatim.output(ln: ""))
          ).repeat.as(:code_block) >>
          (
            (continuation >> code_fence_close) | continuation.absent? | any.absent?
          )
        end


        rule(:block_quote_marker) do
          non_indent_space >>
          str(">") >>
          str(" ").maybe
        end

        # This implements laziness, which is context-sensitive:
        # "only applies to lines that would have been continuations of
        # paragraphs had they been prepended with block quote markers"
        # means we *actually* must be inside of a continueable paragraph.
        #
        # Cannot be a `rule` as usual with `dynamic`.
        def block_quote_cont
          dynamic do |src, ctx|
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
              (block | any.absent?.output("")) >>
              (
                continuation >>
                (block | any.absent?.output(""))
              ).repeat
            ).as(:block_quote)
          end
        end


        rule(:paragraph_interrupt) do
          blank_line | atx_heading | thematic_break |
          code_fence_open | block_quote
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
            str("-").repeat(1) | str("=").repeat(1)
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

        rule(:block) do
          blank_line | atx_heading | thematic_break |
          indented_code_block | fenced_code_block |
          block_quote | setext_heading | paragraph
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
      end
    end
  end
end
