# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module AsciiDoc
    # Parsanol::Transform subclass that converts AST to AsciiDoc model objects.
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
    class Transformer < Parsanol::Transform
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
      autoload :AttributeListNormalizer, "#{__dir__}/transformer/attribute_list_normalizer"
      autoload :BlockTypeClassifier, "#{__dir__}/transformer/block_type_classifier"
      autoload :TableLayout, "#{__dir__}/transformer/table_layout"
      autoload :TableCellBuilder, "#{__dir__}/transformer/table_cell_builder"
      autoload :SourceLineExtractor, "#{__dir__}/transformer/source_line_extractor"

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
              if text.is_a?(Model::Base) && text.class.attributes.key?(:content)
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

      # Helper method for parsing inline content from raw text.
      # Kept as a thin delegator for backwards compatibility; implementation
      # lives in TableCellBuilder (table cells are the primary consumer).
      def self.parse_inline_content(text, style = nil)
        TableCellBuilder.parse_inline_content(text, style)
      end

      def self.parse_block_content(text)
        TableCellBuilder.parse_block_content(text)
      end

      def self.build_table_cell(format, content)
        TableCellBuilder.build(format, content)
      end

      def self.parse_cols_attribute(attrs)
        TableLayout.parse_cols_attribute(attrs)
      end

      def self.group_cells_into_rows(cells, explicit_col_count = nil)
        TableLayout.group_cells_into_rows(cells, explicit_col_count)
      end

      def self.infer_column_count(cells)
        TableLayout.infer_column_count(cells)
      end

      def self.regroup_table_rows(rows, attrs = nil)
        TableLayout.regroup_table_rows(rows, attrs)
      end

      # Transform a syntax tree using this transformer's rules
      #
      # @param syntax_tree [Hash, Array] The AST from the parser
      # @return [Object] The transformed model object(s)
      def self.transform(syntax_tree)
        new.apply(syntax_tree)
      end

      # Convert parser-output "lines" into an array of TextElement model
      # objects. Each line is one of:
      #   - { text: <Array or scalar>, line_break: <str> }
      #   - any other shape (passed through unchanged)
      #
      # Used by the paragraph and reviewer_note rules to share the same
      # line-shape handling (DRY).
      def self.lines_to_text_elements(lines)
        # Parsanol may deliver `lines` as a single Hash (one line captured)
        # or an Array of Hashes (multiple lines). `Array(hash)` converts
        # to nested pairs, which we don't want — normalize explicitly.
        normalized = case lines
                     when nil then []
                     when Array then lines
                     when Hash then [lines]
                     else Array(lines)
                     end
        normalized.map do |line|
          next line unless line.is_a?(Hash) && line.key?(:text)

          text_content = line[:text]
          # `text_content` may be a single Hash (one inline), an Array
          # of Hashes (multiple inlines), or a String. Normalize to an
          # Array of Hashes for uniform processing.
          text_array = case text_content
                       when Array then text_content
                       when Hash then [text_content]
                       when String then [{ text: text_content }]
                       else [{ text: text_content.to_s }]
                       end
          transformed = text_array.map do |item|
            item.is_a?(Hash) ? new.apply(item) : item
          end

          Model::TextElement.new(
            content: transformed,
            line_break: line[:line_break]
          )
        end
      end

      # Split `:lines` entries that span multiple source lines (via
      # text_any greedy-matching across hard_line_break). Each call
      # returns one entry per logical source line: when a line entry's
      # `:text` array contains a `hard_line_break`, the entry is split
      # at each hard_break, producing N+1 entries for N hard breaks.
      # The hard_break is preserved as the `:line_break` of its segment.
      #
      # Without this, a dd source like:
      #   `term::` First line. +
      #   +
      #   attached
      # produces a single `:lines` entry whose text contains
      # ["First line.", hard_line_break(" +\n"), "+", "attached..."],
      # which the renderer joins into "First line. + attached" — the
      # `+` continuation marker ends up inside the dd's text instead
      # of triggering the attached-block path.
      #
      # Used by the dlist transformer before lines_to_text_elements.
      def self.split_lines_on_hard_break(lines)
        normalized = case lines
                     when nil then []
                     when Array then lines
                     when Hash then [lines]
                     else Array(lines)
                     end
        normalized.flat_map do |line|
          next [line] unless line.is_a?(Hash) && line[:text].is_a?(Array)
          next [line] unless line[:text].any? { |p| p.is_a?(Hash) && p.key?(:hard_line_break) }

          segments = []
          current_text = []
          current_break = nil
          line[:text].each do |part|
            if part.is_a?(Hash) && part.key?(:hard_line_break)
              segments << { text: current_text, line_break: part[:hard_line_break] }
              current_text = []
              current_break = :had_hard_break
            else
              current_text << part
            end
          end
          # Final segment gets the original line's line_break (or empty
          # if it ended with a hard break).
          final_break = current_break == :had_hard_break ? "\n" : line[:line_break]
          segments << { text: current_text, line_break: final_break }
          # Drop leading empty segment if the line started with a hard break
          # (shouldn't happen in practice but be defensive).
          segments.reject { |s| s[:text].empty? && s != segments.last }
        end
      end

      # Legacy transform method (deprecated)
      # @deprecated Use {.transform} instead
      def self.legacy_transform(syntax_tree)
        new.apply(syntax_tree)
      end

      # Single deepening seam for source_line propagation. Parsanol's
      # transform pipeline funnels every rule block through
      # +call_on_match(bindings, block)+; overriding it lets us post-
      # process the block's result and inject +source_line+ from the
      # matched bindings, so individual rules no longer need to call
      # SourceLineExtractor.extract themselves (DRY — was 47 call
      # sites across 7 rule files).
      #
      # Safety:
      #   * Only Model::Base results get an injection — Strings, Arrays,
      #     and intermediate hashes pass through unchanged.
      #   * Existing explicit source_line values are preserved — the
      #     injection is fill-in-the-blank, never overwrite.
      #   * No Slice in the bindings → SourceLineExtractor returns nil,
      #     no injection (synthetic transformations stay clean).
      def call_on_match(bindings, block)
        result = super
        return result unless result.is_a?(Model::Base)
        return result if result.source_line

        line = self.class::SourceLineExtractor.extract(bindings)
        result.source_line = line if line
        result
      end
    end
  end
end
