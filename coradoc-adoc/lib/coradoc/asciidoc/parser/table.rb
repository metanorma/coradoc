# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Table
        # AsciiDoc Table Parser
        #
        # Table syntax:
        # - Table starts with: {delimiter}===
        # - Table ends with: {delimiter}===
        # - Delimiter can be: | ! , : ; (and other punctuation)
        # - Cells are separated by: {delimiter}
        # - Rows can span multiple lines using " +" at end of line
        #
        # IMPORTANT: AsciiDoc table row semantics
        # - Column count is determined by:
        #   1. `cols` attribute (e.g., [cols="3"] or [cols="1,a,a"])
        #   2. First row's cell count (if no cols attribute)
        # - A new row starts when:
        #   1. Previous row has `column_count` cells
        #   2. A line starts with the cell delimiter (indicates new row on next line)
        # - Cells on the same line are part of the same row
        #
        # Example:
        # |===
        # | A | B | C     <- Row 1 (3 cells, defines 3 columns)
        # | D              <- Cell 1 of Row 2
        # | E              <- Cell 2 of Row 2
        # | F              <- Cell 3 of Row 2
        # | G | H | I      <- Row 3
        # |===
        #
        # Cell format specification (before cell delimiter):
        # Format: [colspan][.rowspan][halign][valign][style][*]
        #
        # Examples:
        # - "|===" starts a table with | as cell delimiter
        # - "2|" cell spanning 2 columns
        # - ".3|" cell spanning 3 rows
        # - "^e|" centered cell with emphasis style

        def table
          element_id.maybe >>
            (attribute_list >> newline).maybe >>
            block_title.maybe >>
            (attribute_list >> newline).maybe >>
            table_start.capture(:table_delim) >>
            line_ending >>
            table_rows.as(:rows) >>
            table_end >>
            (line_ending | eof?)
        end

        # Match opening delimiter: any valid delimiter char followed by ===
        # Valid delimiter chars: | ! , : ; (punctuation commonly used)
        def table_start
          match['|!,:;'].as(:delim_char) >> str('===')
        end

        # Match closing delimiter using the captured delimiter char
        def table_end
          dynamic do |_s, c|
            delim = c.captures[:table_delim]
            if delim.is_a?(Hash) && delim[:delim_char]
              str(delim[:delim_char]) >> str('===')
            else
              str('|===')
            end
          end
        end

        # Match all rows until closing delimiter
        # A row is a sequence of cells until:
        # 1. End of line (next cells start on new line = new row)
        # 2. Closing delimiter
        def table_rows
          dynamic do |_s, c|
            delim = c.captures[:table_delim]
            delim_char = if delim.is_a?(Hash) && delim[:delim_char]
                           delim[:delim_char]
                         else
                           '|'
                         end
            closing_delim = "#{delim_char}==="

            # Match rows until we hit the closing delimiter
            (
              str(closing_delim).absent? >>
              table_row(delim_char, closing_delim).as(:row)
            ).repeat(1)
          end
        end

        # Match a single table row
        # A row consists of cells on the same line (until newline)
        def table_row(delim_char, closing_delim)
          dynamic do
            # Match cells until we hit a newline or closing delimiter
            (
              str(closing_delim).absent? >>
              (newline >> str(delim_char)).absent? >>
              table_cell(delim_char, closing_delim).as(:cell)
            ).repeat(1).as(:cells) >>
              # Consume the newline at end of row (if present)
              newline
          end
        end

        # Match a single table cell
        # A cell starts with delimiter, contains content
        def table_cell(delim_char, closing_delim)
          dynamic do
            # Cell format spec (optional) + delimiter + content
            # Leading space is optional (cells can start at column 0)
            literal_space?.maybe >>
              cell_format_spec.maybe.as(:cell_format) >>
              str(delim_char) >>
              cell_content(delim_char, closing_delim).as(:text)
          end
        end

        # Match cell content - everything until next cell delimiter
        # IMPORTANT: Must not consume format specs that belong to the next cell
        # Supports multi-line cells with " +" continuation
        def cell_content(delim_char, closing_delim)
          dynamic do
            # Pattern for format spec followed by delimiter
            # Format specs contain: digits, dots, alignment (^<>), style letters, +
            # Using alternation to avoid regex character class issues with ^
            format_spec_char = (
              match['0-9'] | match['.<>'] | match['dsemalhv'] | str('+') | str('^')
            )
            format_spec_then_delim = (
              format_spec_char >>
              format_spec_char.repeat(0) >>
              str(delim_char)
            )

            # Row boundary: newline followed by (plain delimiter OR format spec + delimiter)
            # This detects when the next line is a new row
            new_row_signal = newline >> (str(delim_char) | format_spec_then_delim)

            # A single content character - match any char that doesn't signal end of cell
            (
              str(closing_delim).absent? >>
              new_row_signal.absent? >>
              str(delim_char).absent? >>
              format_spec_then_delim.absent? >>
              any
            ).repeat(0)
          end
        end

        # Match cell format specification
        # Format: [colspan][.rowspan][halign][valign][style][*]
        # Using alternation to avoid regex character class issues with ^
        def cell_format_spec
          (
            match['0-9'] | match['.<>'] | match['dsemalhv'] | str('+') | str('^')
          ).repeat(1)
        end
      end
    end
  end
end
