# frozen_string_literal: true

module Coradoc
  module Plugin
    module Kotoshu
      # Walks a Coradoc CoreModel tree and yields TextSpan structs describing
      # each text-bearing leaf (paragraph, list item, table cell, section
      # title, footnote, etc.).
      #
      # Source code, literal, listing, pass, and comment blocks are skipped
      # — their content is not prose and would just generate noise.
      #
      # Each TextSpan carries:
      #   text       — the flat prose string to check
      #   element    — a stable label (e.g. "section[title]", "paragraph",
      #                "list_item", "table_cell", "footnote")
      #   section    — the enclosing section title (for grouping in the report)
      #   line_hint  — best-effort 1-based source line, found by scanning the
      #                original source for the span's first non-trivial token.
      #                nil when no match can be found.
      class TextExtractor
        TextSpan = Struct.new(:text, :element, :section, :line_hint, keyword_init: true)

        def self.extract(document, source: nil)
          new(source: source).extract(document)
        end

        def initialize(source: nil)
          @source_lines = source&.split("\n", -1)
          @spans = []
          @section_path = []
        end

        # Returns an Array<TextSpan>.
        def extract(document)
          visit_document(document)
          @spans
        end

        private

        def visit_document(document)
          return unless document

          # Document-level metadata (author, rev, attributes) is exposed as
          # child Blocks with element_type == "paragraph" near the top. We
          # filter those out by inspecting the content (skip :key: val lines).
          Array(document.children).each { |child| visit_any(child) }
        end

        def visit_any(node)
          return unless node

          case node
          when Coradoc::CoreModel::StructuralElement
            visit_structural(node)
          when Coradoc::CoreModel::Block
            visit_block(node)
          when Coradoc::CoreModel::ListBlock
            visit_list_block(node)
          when Coradoc::CoreModel::ListItem
            visit_list_item(node)
          when Coradoc::CoreModel::Table
            visit_table(node)
          when Coradoc::CoreModel::TableRow
            visit_table_row(node)
          when Coradoc::CoreModel::TableCell
            visit_table_cell(node)
          when Coradoc::CoreModel::InlineElement
            visit_inline(node)
          when Coradoc::CoreModel::DefinitionList
            visit_definition_list(node)
          when Coradoc::CoreModel::DefinitionItem
            visit_definition_item(node)
          when Coradoc::CoreModel::Term
            visit_term(node)
          when Coradoc::CoreModel::Footnote
            visit_footnote(node)
          when Coradoc::CoreModel::QuoteBlock, Coradoc::CoreModel::ExampleBlock,
               Coradoc::CoreModel::SidebarBlock, Coradoc::CoreModel::OpenBlock,
               Coradoc::CoreModel::AnnotationBlock, Coradoc::CoreModel::ReviewerBlock,
               Coradoc::CoreModel::VerseBlock
            visit_block_like(node)
          when Coradoc::CoreModel::TextContent
            visit_text_content(node)
          when String
            emit_string(node, 'paragraph')
          else
            visit_unknown(node)
          end
        end

        def visit_structural(node)
          if node.element_type == 'section'
            push_section(node.title) do
              visit_children(node)
            end
          else
            visit_children(node)
          end
        end

        def visit_block(node)
          return unless node.prose?

          text = flat_text(node)
          emit_text(text, element_label(node), source_line: node.source_line) if text && !metadata_only?(text)
          visit_children(node)
        end

        def visit_list_block(node)
          node.items.each { |item| visit_list_item(item) }
        end

        def visit_list_item(node)
          text = flat_text(node)
          emit_text(text, 'list_item', source_line: node.source_line) if text && !text.empty?
          visit_children(node)
          visit_any(node.nested_list) if node.nested_list
        end

        def visit_table(node)
          node.rows.each { |row| visit_table_row(row) }
        end

        def visit_table_row(node)
          node.cells.each { |cell| visit_table_cell(cell) }
        end

        def visit_table_cell(node)
          text = flat_text(node)
          emit_text(text, 'table_cell', source_line: node.source_line) if text && !text.empty?
          visit_children(node)
        end

        def visit_inline(node)
          text = node.content.to_s
          emit_text(text, 'inline', source_line: node.source_line) if text && !text.empty?
          Array(node.nested_elements).each { |child| visit_inline(child) }
        end

        def visit_definition_list(node)
          node.items.each { |item| visit_any(item) }
        end

        def visit_definition_item(node)
          term_text = node.term.to_s
          emit_text(term_text, 'definition_term', source_line: node.source_line) if term_text && !term_text.empty?
          node.definitions.each do |defn|
            emit_text(defn.to_s, 'definition', source_line: node.source_line) unless defn.to_s.empty?
          end
          visit_any(node.nested) if node.nested
        end

        def visit_term(node)
          text = flat_text(node)
          emit_text(text, 'definition_term', source_line: node.source_line) if text && !text.empty?
        end

        def visit_footnote(node)
          text = flat_text(node)
          emit_text(text, 'footnote', source_line: node.source_line) if text && !text.empty?
        end

        def visit_unknown(node)
          raise ArgumentError, "TextExtractor cannot dispatch on #{node.class}"
        end

        def visit_text_content(node)
          # TextContent is a leaf inline node. Its text is folded into the
          # parent Block's flat_text by CoreModel; emitting it separately
          # would double-count every paragraph.
        end

        def visit_children(node)
          Array(node.children).each { |child| visit_any(child) }
        end

        def push_section(title)
          previous = @section_path.dup
          @section_path << title.to_s unless title.to_s.empty?
          yield
        ensure
          @section_path = previous
        end

        def emit_text(text, element, source_line: nil)
          return if text.nil? || text.empty?

          stripped = text.strip
          return if stripped.empty?

          @spans << TextSpan.new(
            text: stripped,
            element: element,
            section: @section_path.last,
            line_hint: source_line || locate_line(stripped)
          )
        end

        alias emit_string emit_text

        # Document header cruft (author lines, :attribute: lines) shows up as
        # paragraph Blocks at the top of the document. Skip them so we don't
        # surface "Author" or "toc" as misspellings. The block's content is
        # flattened to a single string in coradoc 2.x, so we pattern-match
        # against the whole string rather than line-by-line.
        #
        # TODO: replace with typed Document#author / Document#attributes
        # access once TODO 33 lands (see TODO.refactor/33).
        def metadata_only?(text)
          stripped = text.strip
          return true if stripped.empty?

          # Pure :attribute: value lines (joined into one string). Uses
          # atomic group `(?>...)` to prevent ReDoS backtracking on
          # pathological `:a::a::a:...` inputs (CodeQL flagged the
          # naive nested-quantifier form).
          attr_segment = /(?>:[^:\s]+:[^\n]*)/
          attr_only = /\A(?:#{attr_segment})+\z/
          return true if stripped.match?(attr_only)

          # Author Name <email> followed by zero or more :attr: lines
          author_block = /\A[\w\s.\-]+<[\w.\-]+@[\w.\-]+>\s*/
          remainder = stripped.sub(author_block, '')
          remainder = remainder.strip
          remainder.empty? || remainder.match?(attr_only)
        end

        # flat_text is declared on CoreModel::Base, so every visited node
        # responds to it. Block-level elements without textual content
        # (ListBlock, Table) return "" by default.
        def flat_text(node)
          node.flat_text
        end

        def element_label(node)
          sem = semantic_type_of(node)
          sem ? sem.to_s : class_basename(node).gsub(/Block$/, '').downcase
        end

        # resolve_semantic_type lives on CoreModel::Block; non-Block nodes
        # use their class identity as the semantic label.
        def semantic_type_of(node)
          case node
          when Coradoc::CoreModel::Block then node.resolve_semantic_type
          end
        end

        def class_basename(node)
          node.class.name.split('::').last
        end

        def locate_line(text)
          return nil unless @source_lines

          probe = first_probe_token(text)
          return nil unless probe

          @source_lines.each_with_index do |line, idx|
            return idx + 1 if line.include?(probe)
          end
          nil
        end

        # Pick a word from the span that's unlikely to appear on every line.
        # Skip very short tokens and ones that look like attribute syntax.
        def first_probe_token(text)
          text.split(/\s+/).find do |tok|
            tok.length >= 4 && !tok.match?(/\A[:=]/) && !tok.match?(/\A\d+\z/)
          end
        end
      end
    end
  end
end
