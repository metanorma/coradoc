# frozen_string_literal: true

require 'parslet'

module Coradoc
  module AsciiDoc
    # Parslet::Transform subclass that converts AST to AsciiDoc model objects.
    #
    # This transformer uses a modular rule system where each group of rules
    # is defined in a separate file for maintainability.
    #
    # Rule modules (each autoloaded):
    # - HeaderRules: Document header, author, revision
    # - InlineRules: Inline formatting (bold, italic, etc.)
    # - TextRules: Text elements and paragraphs
    # - BlockRules: Block elements (example, admonition, etc.)
    # - ListRules: List items and list types
    # - StructuralRules: Sections, tables, documents
    # - MiscRules: Comments, attributes, media elements
    #
    class Transformer < Parslet::Transform
      # Autoload rule modules at the class level.
      # Each rule file reopens this class and defines a module inside it.
      # The file path matches the expected constant path.
      autoload :HeaderRules, "#{__dir__}/transformer/header_rules"
      autoload :InlineRules, "#{__dir__}/transformer/inline_rules"
      autoload :TextRules, "#{__dir__}/transformer/text_rules"
      autoload :BlockRules, "#{__dir__}/transformer/block_rules"
      autoload :ListRules, "#{__dir__}/transformer/list_rules"
      autoload :StructuralRules, "#{__dir__}/transformer/structural_rules"
      autoload :MiscRules, "#{__dir__}/transformer/misc_rules"

      # Apply all rule modules (triggers autoload)
      HeaderRules.apply(self)
      InlineRules.apply(self)
      TextRules.apply(self)
      BlockRules.apply(self)
      ListRules.apply(self)
      StructuralRules.apply(self)
      MiscRules.apply(self)

      # Helper method for extracting inline content (used by InlineRules)
      def self.extract_inline_content(data)
        if data.is_a?(Hash) && data.key?(:content)
          data[:content]
        elsif data.is_a?(Array)
          data.map do |item|
            if item.is_a?(Hash) && item.key?(:text)
              text = item[:text]
              if text.respond_to?(:content)
                text.content
              elsif text.is_a?(Model::Base)
                text
              else
                text.to_s
              end
            else
              item
            end
          end
        else
          data
        end
      end

      # Helper method for extracting simple inline content
      def self.extract_simple_inline_content(data)
        if data.is_a?(Hash) && data.key?(:content)
          data[:content]
        elsif data.is_a?(Array)
          data.map do |item|
            item.is_a?(Hash) && item.key?(:text) ? item[:text].to_s : item
          end.join
        else
          data
        end
      end

      # Helper method for parsing inline content from raw text
      # This is used for table cells where content is captured as raw text
      # @param text [String] Raw text to parse
      # @param style [String, nil] Cell style ('a' for AsciiDoc, 'l' for literal, etc.)
      # @return [Array<TextElement>] Parsed content as array of TextElement objects
      def self.parse_inline_content(text, style = nil)
        return [Coradoc::AsciiDoc::Model::TextElement.new(content: '')] if text.nil? || text.to_s.strip.empty?

        # For AsciiDoc style cells, parse as block content
        return parse_block_content(text) if style == 'a'

        # For literal style cells, preserve text as-is
        return [Coradoc::AsciiDoc::Model::TextElement.new(content: text.to_s)] if style == 'l'

        # For default cells, parse inline content
        parser = Coradoc::AsciiDoc::Parser::Base.new
        begin
          ast = parser.text_any.parse(text.to_s)
          # Transform the AST to model objects
          transformed = new.apply(ast)

          # Wrap in TextElement
          content_array = transformed.is_a?(Array) ? transformed : [transformed]
          [Coradoc::AsciiDoc::Model::TextElement.new(content: content_array)]
        rescue Parslet::ParseFailed
          # If parsing fails, return the text as a simple TextElement
          [Coradoc::AsciiDoc::Model::TextElement.new(content: text.to_s)]
        end
      end

      # Parse block-level AsciiDoc content (for 'a' style cells)
      # @param text [String] Raw text containing AsciiDoc blocks
      # @return [Array] Parsed block content
      def self.parse_block_content(text)
        return [Coradoc::AsciiDoc::Model::TextElement.new(content: '')] if text.nil? || text.to_s.strip.empty?

        parser = Coradoc::AsciiDoc::Parser::Base.new
        text_str = text.to_s

        # Try parsing as a list if content contains list markers
        # List markers can appear after other content (e.g., "Title:\n\n* item")
        if /^(\*+|-+|\d+\.)/m.match?(text_str)
          # Extract just the list portion
          list_match = text_str.match(/\n(\*+|-+|\d+\.)(.*)$/m)
          if list_match
            list_text = list_match[1] + list_match[2]
            begin
              ast = parser.list.parse(list_text)
              transformed = new.apply(ast)

              # Parse the text before the list as inline content
              before_list = text_str[0, list_match.begin(1) - 1].strip
              before_elements = []
              unless before_list.empty?
                begin
                  before_ast = parser.text_any.parse(before_list)
                  before_transformed = new.apply(before_ast)
                  before_array = before_transformed.is_a?(Array) ? before_transformed : [before_transformed]
                  before_elements = [Coradoc::AsciiDoc::Model::TextElement.new(content: before_array)]
                rescue Parslet::ParseFailed
                  before_elements = [Coradoc::AsciiDoc::Model::TextElement.new(content: before_list)]
                end
              end

              return before_elements + [transformed]
            rescue Parslet::ParseFailed
              # Fall through to inline parsing
            end
          end
        end

        # Try parsing as inline content
        begin
          ast = parser.text_any.parse(text_str)
          transformed = new.apply(ast)
          content_array = transformed.is_a?(Array) ? transformed : [transformed]
          [Coradoc::AsciiDoc::Model::TextElement.new(content: content_array)]
        rescue Parslet::ParseFailed
          # If parsing fails, return the text as a simple TextElement
          [Coradoc::AsciiDoc::Model::TextElement.new(content: text_str)]
        end
      end

      # Helper method for building table cells with format specification
      # @param format [Hash, String, Object] Cell format specification from parser
      # @param content [Object] Cell content
      # @return [Model::TableCell] Table cell model with parsed attributes
      def self.build_table_cell(format, content)
        cell_opts = {}

        # Extract style first for content parsing
        style = nil

        # Parse format specification if present
        if format.is_a?(Hash)
          # Colspan
          cell_opts[:colspan] = format[:colspan].to_i if format[:colspan]

          # Rowspan (remove leading dot)
          if format[:rowspan]
            rowspan_str = format[:rowspan].to_s
            rowspan_str = rowspan_str.sub(/^\./, '')
            cell_opts[:rowspan] = rowspan_str.to_i if rowspan_str.match?(/^\d+$/)
          end

          # Horizontal alignment
          cell_opts[:halign] = format[:halign].to_s if format[:halign]

          # Vertical alignment (remove leading dot)
          if format[:valign]
            valign_str = format[:valign].to_s
            valign_str = valign_str.sub(/^\./, '')
            cell_opts[:valign] = valign_str if %w[< ^ >].include?(valign_str)
          end

          # Style
          style = format[:style].to_s if format[:style]
          cell_opts[:style] = style

          # Repeat marker
          cell_opts[:repeat] = true if format[:repeat]
        elsif format.is_a?(String) || format.respond_to?(:to_s)
          # Parse format string like ".2+^.^" or "4+^" or ".3+a"
          # Format: [colspan][.rowspan][halign][valign][style][*]
          format_str = format.to_s

          # Parse colspan (digits before +)
          cell_opts[:colspan] = Regexp.last_match(1).to_i if format_str =~ /^(\d+)\+/

          # Parse rowspan (.digits)
          cell_opts[:rowspan] = Regexp.last_match(1).to_i if format_str =~ /\.(\d+)/

          # Parse horizontal alignment (^ < >)
          # Note: In AsciiDoc, ^ is center, < is left, > is right
          cell_opts[:halign] = Regexp.last_match(0) if format_str =~ /[<>^]/

          # Parse vertical alignment (.<. ^. >.)
          cell_opts[:valign] = Regexp.last_match(0)[1] if format_str =~ /\.[.^<>]/

          # Parse style (d=decimal, s=strong, e=emphasis, m=monospace, a=asciidoc, l=literal, h=header)
          style = Regexp.last_match(0) if format_str =~ /[dsemalhv]/
          cell_opts[:style] = style

          # Parse repeat marker
          cell_opts[:repeat] = true if format_str.include?('*')
        end

        # Parse content based on style
        parsed_content = parse_inline_content(content, style)
        cell_opts[:content] = parsed_content

        Model::TableCell.new(**cell_opts)
      end

      # Parse the cols attribute to determine column count
      # @param attrs [Model::AttributeList, nil] Table attributes
      # @return [Integer, nil] Column count or nil if not specified
      def self.parse_cols_attribute(attrs)
        return nil if attrs.nil?

        # Get the cols value from named attributes
        cols_value = if attrs.respond_to?(:named)
                       attrs.named.find { |n| n.name.to_s == 'cols' }&.value
                     elsif attrs.is_a?(Hash)
                       attrs['cols'] || attrs[:cols]
                     end

        return nil if cols_value.nil?

        # cols can be:
        # - A single number: "3" -> 3 columns
        # - A list: "1,2,1" -> 3 columns
        # - With multipliers: "3*" -> 3 columns
        # - Quoted: "\"3\"" -> 3 columns
        cols_str = cols_value.is_a?(Array) ? cols_value.first.to_s : cols_value.to_s

        # Remove surrounding quotes if present
        cols_str = cols_str.gsub(/^["']|["']$/, '')

        # Handle multiplier syntax: "3*" means 3 columns
        return Regexp.last_match(1).to_i if cols_str =~ /^(\d+)\*$/

        # Handle comma-separated list: count the parts
        return cols_str.split(',').size if cols_str.include?(',')

        # Single number
        cols_str.to_i if /^\d+$/.match?(cols_str)
      end

      # Group cells into rows based on column count
      #
      # AsciiDoc table row semantics:
      # - Column count is determined by cols attribute or first row
      # - A new row starts when previous row has `column_count` cells
      # - Cells with colspan > 1 take multiple column slots
      #
      # @param cells [Array<Model::TableCell>] Flat list of cells
      # @param explicit_col_count [Integer, nil] Column count from cols attribute
      # @return [Array<Model::TableRow>] Grouped rows
      def self.group_cells_into_rows(cells, explicit_col_count = nil)
        return [] if cells.nil? || cells.empty?

        # Normalize cells to ensure they're TableCell objects
        normalized_cells = cells.map do |cell|
          case cell
          when Model::TableCell
            cell
          when Hash
            content = cell[:text] || cell[:content] || ''
            Model::TableCell.new(content: parse_inline_content(content))
          else
            Model::TableCell.new(content: parse_inline_content(cell))
          end
        end

        # Determine column count
        # If explicit_col_count is provided, use it
        # Otherwise, count cells until we find a row boundary
        col_count = explicit_col_count

        if col_count.nil? || col_count.zero?
          # Infer from first row - count cells until we have a complete row
          # A complete row is when the total column slots equals a consistent number
          col_count = infer_column_count(normalized_cells)
        end

        # If still no column count, assume all cells are one row
        col_count = normalized_cells.size if col_count.nil? || col_count.zero?

        # Group cells into rows
        rows = []
        current_row_cells = []
        current_col_slots = 0

        normalized_cells.each do |cell|
          # Get colspan (default 1)
          colspan = (cell.respond_to?(:colspan) && cell.colspan) || 1

          current_row_cells << cell
          current_col_slots += colspan

          # Check if row is complete
          next unless current_col_slots >= col_count

          rows << Model::TableRow.new(columns: current_row_cells)
          current_row_cells = []
          current_col_slots = 0
        end

        # Handle remaining cells (incomplete last row)
        rows << Model::TableRow.new(columns: current_row_cells) if current_row_cells.any?

        rows
      end

      # Infer column count from cells
      # Look for patterns where rows have consistent cell counts
      # Prefers LARGER valid column counts (more likely to be correct)
      def self.infer_column_count(cells)
        return nil if cells.nil? || cells.empty?

        # Count column slots for each cell
        col_slots = cells.map do |cell|
          (cell.respond_to?(:colspan) && cell.colspan) || 1
        end

        total_cells = col_slots.sum

        # Find all valid column counts
        possible_cols = (1..[total_cells, 12].min).select do |candidate|
          next false if candidate > total_cells
          next false if total_cells % candidate != 0

          # Verify that the cells distribute evenly
          slots_used = 0
          valid = true

          col_slots.each do |slots|
            slots_used += slots
            if slots_used == candidate
              slots_used = 0
            elsif slots_used > candidate
              valid = false
              break
            end
          end

          valid && slots_used.zero?
        end

        # Return the largest valid column count
        # (more likely to represent actual table structure)
        possible_cols.max || col_slots.first || 1
      end

      # Transform a syntax tree using this transformer's rules
      #
      # @param syntax_tree [Hash, Array] The AST from the parser
      # @return [Object] The transformed model object(s)
      def self.transform(syntax_tree)
        new.apply(syntax_tree)
      end

      # Legacy transform method (deprecated)
      # @deprecated Use {.transform} instead
      def self.legacy_transform(syntax_tree)
        new.apply(syntax_tree)
      end
    end
  end
end
