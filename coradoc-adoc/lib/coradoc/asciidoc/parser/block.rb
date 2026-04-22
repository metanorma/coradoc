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
          (example_block(n_deep) |
          sidebar_block(n_deep) |
          source_block(n_deep) |
          quote_block(n_deep) |
          pass_block(n_deep) |
          open_block(n_deep)).as(:block)
        end

        def reviewer_note_block(_n_deep = 3)
          # Match blocks with reviewer attribute
          # This should only match when attribute_list contains reviewer=
          # For now, we'll make it not match anything specific
          # The block() method will handle these cases
          str('').absent? # Never matches - placeholder for future implementation
        end

        def example_block(n_deep)
          block_style(n_deep, '=', 4)
        end

        def pass_block(n_deep)
          block_style(n_deep, '+', 4, :pass)
        end

        def quote_block(n_deep)
          block_style(n_deep, '_', 4)
        end

        def sidebar_block(n_deep)
          block_style(n_deep, '*', 4)
        end

        def source_block(n_deep)
          block_style(n_deep, '-', 4)
        end

        # Open block: exactly 2 dashes (cannot nest within itself)
        def open_block(n_deep)
          block_style_exact(n_deep, '-', 2)
        end

        def block_title
          str('.') >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (line_start? >> str('[') >> str('[').absent? >>
            str(type).as(:type) >>
            str(']')) >> newline # |
        end

        def block_content(n_deep = 3)
          c = block_image |
              list |
              text_line |
              empty_line.as(:line_break)
          c |= block(n_deep - 1) if n_deep.positive?
          c.repeat(1)
        end

        # Block delimiter: 4+ identical characters (or 2 for open block)
        # NOTE: repeat(4,) means 4 or more (not exactly 4)
        def block_delimiter
          line_start? >>
            ((str('*') |
              str('=') |
              str('_') |
              str('+') |
              str('-')).repeat(4) | # 4+ characters for most blocks
              str('-').repeat(2, 2)) >> # Exactly 2 for open block
            newline
        end

        def element_attributes
          block_title.maybe >>
            element_id.maybe >>
            (attribute_list >> newline).maybe >>
            block_title.maybe >>
            newline.maybe >>
            (attribute_list >> newline).maybe >>
            element_id.maybe
        end

        # Block style parser with variable delimiter length
        # @param n_deep [Integer] Nesting depth for nested blocks
        # @param delimiter [String] The delimiter character ("=", "-", "_", "*", "+")
        # @param repeater [Integer] Minimum number of delimiter characters (default: 4)
        # @param type [Symbol] Block type for special handling (e.g., :pass)
        def block_style(n_deep = 3, delimiter = '*', repeater = 4, type = nil)
          # repeat(repeater,) means repeater or more characters
          current_delimiter = str(delimiter).repeat(repeater).capture(:delimit)
          closing_delimiter = dynamic do |_s, c|
            str(c.captures[:delimit].to_s.strip)
          end

          # Create a block content parser that respects the closing delimiter
          # This prevents nested blocks from consuming the closing delimiter
          block_content_with_closing = dynamic do |_s, c|
            delim_str = c.captures[:delimit].to_s.strip
            closing_pattern = str(delim_str) >> newline

            # Build content that doesn't match the closing delimiter
            content = block_image | list | text_line | empty_line.as(:line_break)
            if n_deep.positive?
              # For nested blocks, also prevent them from consuming the closing delimiter
              content |= block(n_deep - 1)
            end

            # Each content element must not start with the closing delimiter
            (closing_pattern.absent? >> content).repeat(1)
          end

          element_attributes >>
            (line_start? >> attribute_list >> newline).maybe >>
            line_start? >>
            current_delimiter.as(:delimiter) >> newline >>
            if type == :pass
              (text_line | empty_line.as(:line_break)).repeat(1).as(:lines)
            else
              # Use dynamic block content that respects closing delimiter
              block_content_with_closing.as(:lines)
            end >>
            line_start? >>
            closing_delimiter >> newline
        end

        # Block style parser with EXACT delimiter length (for open blocks)
        # Open blocks use exactly 2 dashes and cannot nest within themselves
        def block_style_exact(n_deep = 3, delimiter = '-', exact_chars = 2, type = nil)
          current_delimiter = str(delimiter).repeat(exact_chars, exact_chars).capture(:delimit)
          closing_delimiter = dynamic do |_s, c|
            str(c.captures[:delimit].to_s.strip)
          end

          # Create a block content parser that respects the closing delimiter
          block_content_with_closing = dynamic do |_s, c|
            delim_str = c.captures[:delimit].to_s.strip
            closing_pattern = str(delim_str) >> newline

            content = block_image | list | text_line | empty_line.as(:line_break)
            content |= block(n_deep - 1) if n_deep.positive?

            (closing_pattern.absent? >> content).repeat(1)
          end

          element_attributes >>
            (line_start? >> attribute_list >> newline).maybe >>
            line_start? >>
            current_delimiter.as(:delimiter) >> newline >>
            if type == :pass
              (text_line | empty_line.as(:line_break)).repeat(1).as(:lines)
            else
              block_content_with_closing.as(:lines)
            end >>
            line_start? >>
            closing_delimiter >> newline
        end
      end
    end
  end
end
