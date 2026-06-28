# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Block
        # AsciiDoc Block Delimiter Patterns:
        # - "4+" means 4 or more identical characters
        # - "2+" means 2 or more identical characters
        #
        # Block types by delimiter character:
        # - "=" (4+): Example block (====, =====, etc.)
        # - "-" (4+): Source/listing block (----, -----, etc.)
        # - "-" (2): Open block (--)
        # - "_" (4+): Quote block (____, _____, etc.)
        # - "*" (4+): Sidebar block (****, *****, etc.)
        # - "+" (4+): Pass block (++++, +++++, etc.)
        # - "." (4+): Literal block (...., ....., etc.)
        #
        # Table delimiters:
        # - "|===" defines table boundaries
        # - "|" separates cells within the table

        def block(n_deep = 3)
          (markdown_code_block(n_deep) |
          example_block(n_deep) |
          sidebar_block(n_deep) |
          source_block(n_deep) |
          quote_block(n_deep) |
          pass_block(n_deep) |
          literal_block(n_deep) |
          open_block(n_deep)).as(:block)
        end

        def example_block(n_deep)
          block_style(n_deep, '=', 4)
        end

        def pass_block(n_deep)
          block_style(n_deep, '+', 4, verbatim: true)
        end

        def quote_block(n_deep)
          block_style(n_deep, '_', 4)
        end

        def sidebar_block(n_deep)
          block_style(n_deep, '*', 4)
        end

        def source_block(n_deep)
          block_style(n_deep, '-', 4, verbatim: true)
        end

        def literal_block(n_deep)
          block_style(n_deep, '.', 4, verbatim: true)
        end

        # Open block: exactly 2 dashes (cannot nest within itself)
        def open_block(n_deep)
          block_style_exact(n_deep, '-', 2)
        end

        # Markdown-style fenced code block: triple-backtick (or longer)
        # fence with an optional language tag on the opening line. Behaves
        # as a verbatim source block — same model as `[source,lang]\n----`.
        # Pragmatic permissiveness for content that originates from (or is
        # edited alongside) Markdown; not standard AsciiDoc but widely
        # accepted (GitHub's renderer treats ``` as a listing delimiter).
        def markdown_code_block(n_deep = 3)
          capture_key = :"md_fence_#{n_deep}"
          opening_fence = str('`').repeat(3).capture(capture_key)
          closing_fence = dynamic do |_s, c|
            str(c.captures[capture_key].to_s.strip)
          end
          language = (space? >> match('[A-Za-z0-9_+.-]').repeat(1).as(:language)).maybe

          block_content_with_closing = dynamic do |_s, c|
            c.captures[capture_key].to_s.strip
            closing_pattern = closing_fence >> space? >> newline

            content = text_line(false, unguarded: true, verbatim: true) |
                      empty_line.as(:line_break)

            (closing_pattern.absent? >> content).repeat(1)
          end

          block_header >>
            line_start? >>
            opening_fence.as(:delimiter) >> language >> newline >>
            block_content_with_closing.as(:lines) >>
            line_start? >>
            closing_fence >> space? >> newline
        end

        def block_title
          (line_start? >> block_delimiter.absent?) >>
            str('.') >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (line_start? >> str('[') >> str('[').absent? >>
            str(type).as(:type) >>
            str(']')) >> newline # |
        end

        def block_content(n_deep = 3)
          block_container_content(n_deep).repeat(1)
        end

        # Single source of truth for "what can appear inside a non-verbatim
        # block container". Used by block_content, block_style (non-verbatim
        # branch), and block_style_exact (non-verbatim branch).
        #
        # `table` is listed before `text_line` so a leading `|===` is parsed
        # as a table rather than mis-bracketed as text. The recursive `block`
        # alternative handles every other delimited block.
        def block_container_content(n_deep)
          c = table.as(:table)
          c |= block_image
          c |= block(n_deep - 1) if n_deep.positive?
          c |= list
          c |= text_line(false, unguarded: true)
          c |= empty_line.as(:line_break)
          c
        end

        # Block delimiter: 4+ identical characters, or 2 dashes for open
        # blocks, or 3+ backticks for Markdown-style code fences. Used by
        # paragraph.rb to reject lines that look like block delimiters.
        # NOTE: repeat(4,) means 4 or more (not exactly 4)
        def block_delimiter
          line_start? >>
            ((str('*') |
              str('=') |
              str('_') |
              str('+') |
              str('.') |
              str('-')).repeat(4) | # 4+ characters for most blocks
              str('-').repeat(2, 2) | # Exactly 2 for open block
              str('`').repeat(3)) >> # 3+ for Markdown code fences
            newline
        end

        # Block style parser with variable delimiter length
        # @param n_deep [Integer] Nesting depth for nested blocks
        # @param delimiter [String] The delimiter character ("=", "-", "_", "*", "+", ".")
        # @param repeater [Integer] Minimum number of delimiter characters (default: 4)
        # @param verbatim [Boolean] Treat body as raw text (no substitutions, no nested blocks)
        def block_style(n_deep = 3, delimiter = '*', repeater = 4, verbatim: false)
          capture_key = :"delimit_#{delimiter}_#{n_deep}"
          current_delimiter = str(delimiter).repeat(repeater).capture(capture_key)
          closing_delimiter = dynamic do |_s, c|
            str(c.captures[capture_key].to_s.strip)
          end

          block_content_with_closing = dynamic do |_s, c|
            delim_str = c.captures[capture_key].to_s.strip
            closing_pattern = str(delim_str) >> newline

            # Verbatim blocks (source/listing/literal/pass) treat their body
            # as literal text per the AsciiDoc spec — no substitutions, no
            # nested blocks. Allowing nested block parsing here would consume
            # shorter inner delimiters (e.g. `----` inside `------`) and
            # strip the original structure when serializing back.
            content = if verbatim
                        text_line(false, unguarded: true, verbatim: true) |
                          empty_line.as(:line_break)
                      else
                        block_container_content(n_deep)
                      end

            (closing_pattern.absent? >> content).repeat(1)
          end

          block_header >>
            line_start? >>
            current_delimiter.as(:delimiter) >> newline >>
            block_content_with_closing.as(:lines) >>
            line_start? >>
            closing_delimiter >> newline
        end

        # Block style parser with EXACT delimiter length (for open blocks).
        # Open blocks use exactly 2 dashes. A `[source]`/`[listing]`/`[literal]`
        # positional attribute casts the body to verbatim — block macros like
        # `image::` must survive byte-for-byte, same as delimited source blocks.
        def block_style_exact(n_deep = 3, delimiter = '-', exact_chars = 2)
          capture_key = :"delimit_#{delimiter}_exact_#{exact_chars}_#{n_deep}"
          attr_capture_key = :"#{capture_key}_attrs"
          current_delimiter = str(delimiter).repeat(exact_chars, exact_chars).capture(capture_key)
          closing_delimiter = dynamic do |_s, c|
            str(c.captures[capture_key].to_s.strip)
          end

          # Closure so the call bypasses Parslet's method_missing inside the
          # dynamic block. capture() stashes the parsed AST (a nested Hash for
          # a `[source,ruby]` header). Inspect the structure directly so we
          # don't depend on Ruby's Hash#to_s format (it changed in 3.4).
          verbatim_cast = lambda do |raw|
            values = []
            queue = [raw]
            while (node = queue.shift)
              case node
              when Hash then queue.concat(node.values)
              when Array then queue.concat(node)
              else values << node
              end
            end
            castable = %w[source listing literal]
            values.any? { |v| castable.include?(v.to_s) }
          end

          block_content_with_closing = dynamic do |_s, c|
            delim_str = c.captures[capture_key].to_s.strip
            raw_header = c.captures[attr_capture_key]
            closing_pattern = str(delim_str) >> newline

            content = if verbatim_cast.call(raw_header)
                        text_line(false, unguarded: true, verbatim: true) |
                          empty_line.as(:line_break)
                      else
                        block_container_content(n_deep)
                      end

            (closing_pattern.absent? >> content).repeat(1)
          end

          block_header.capture(attr_capture_key) >>
            line_start? >>
            current_delimiter.as(:delimiter) >> newline >>
            block_content_with_closing.as(:lines) >>
            line_start? >>
            closing_delimiter >> newline
        end
      end
    end
  end
end
