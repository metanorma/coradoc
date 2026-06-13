# frozen_string_literal: true

module Coradoc
  module Mirror
    class MirrorToCoreModel
      # Dispatch table: Mirror node type string → builder lambda.
      # New node types are supported by adding entries (OCP).
      TYPE_BUILDERS = {
        "doc" => ->(t, n) { t.build_document(n) },
        "section" => ->(t, n) { t.build_section(n) },
        "header" => ->(t, n) { t.build_header(n) },
        "preamble" => ->(t, n) { t.build_preamble(n) },
        "paragraph" => ->(t, n) { t.build_paragraph(n) },
        "code_block" => ->(t, n) { t.build_code_block(n) },
        "blockquote" => ->(t, n) { t.build_blockquote(n) },
        "example" => ->(t, n) { t.build_example(n) },
        "sidebar" => ->(t, n) { t.build_sidebar(n) },
        "open_block" => ->(t, n) { t.build_open_block(n) },
        "verse" => ->(t, n) { t.build_verse(n) },
        "horizontal_rule" => ->(t, _n) { t.build_horizontal_rule },
        "admonition" => ->(t, n) { t.build_admonition(n) },
        "bullet_list" => ->(t, n) { t.build_bullet_list(n) },
        "ordered_list" => ->(t, n) { t.build_ordered_list(n) },
        "list_item" => ->(t, n) { t.build_list_item(n) },
        "definition_list" => ->(t, n) { t.build_definition_list(n) },
        "definition_term" => ->(t, n) { t.build_definition_term(n) },
        "definition_description" => ->(t, n) { t.build_definition_description(n) },
        "image" => ->(t, n) { t.build_image(n) },
        "table" => ->(t, n) { t.build_table(n) },
        "table_head" => ->(t, n) { t.build_table_head(n) },
        "table_body" => ->(t, n) { t.build_table_body(n) },
        "table_row" => ->(t, n) { t.build_table_row(n) },
        "table_cell" => ->(t, n) { t.build_table_cell(n) },
        "bibliography" => ->(t, n) { t.build_bibliography(n) },
        "biblio_entry" => ->(t, n) { t.build_biblio_entry(n) },
        "footnotes" => ->(_t, _n) { nil },
        "footnote_entry" => ->(t, n) { t.build_footnote_entry(n) },
        "toc" => ->(t, n) { t.build_toc(n) },
        "toc_entry" => ->(t, n) { t.build_toc_entry(n) },
        "text" => ->(t, n) { t.build_text(n) },
        "soft_break" => ->(t, _n) { t.build_soft_break },
      }.freeze

      def call(mirror_node)
        build_node(mirror_node)
      end

      def build_node(node)
        builder = TYPE_BUILDERS[node.type]
        raise Error, "Unknown mirror node type: #{node.type}" unless builder

        builder.call(self, node)
      end

      def build_content(node)
        return [] unless node.content

        node.content.filter_map { |child| build_node(child) }
      end

      # ── Structural ──

      def build_document(node)
        CoreModel::DocumentElement.new(
          title: node.title,
          id: node.id,
          children: build_content(node),
        )
      end

      def build_section(node)
        CoreModel::SectionElement.new(
          title: node.title,
          level: node.level,
          id: node.id,
          children: build_content(node),
        )
      end

      def build_header(node)
        CoreModel::HeaderElement.new(
          title: node.title,
          level: node.level,
          children: build_content(node),
        )
      end

      def build_preamble(node)
        CoreModel::PreambleElement.new(
          children: build_content(node),
        )
      end

      # ── Blocks ──

      def build_paragraph(node)
        children = build_inline_children(node)
        CoreModel::ParagraphBlock.new(children: children)
      end

      def build_code_block(node)
        text = extract_text(node)
        CoreModel::SourceBlock.new(
          content: text,
          language: node.language,
          title: node.title,
        )
      end

      def build_blockquote(node)
        CoreModel::QuoteBlock.new(
          attribution: node.attribution,
          children: build_content(node),
        )
      end

      def build_example(node)
        CoreModel::ExampleBlock.new(
          title: node.title,
          children: build_content(node),
        )
      end

      def build_sidebar(node)
        CoreModel::SidebarBlock.new(
          title: node.title,
          children: build_content(node),
        )
      end

      def build_open_block(node)
        CoreModel::OpenBlock.new(
          children: build_content(node),
        )
      end

      def build_verse(node)
        text = extract_text(node)
        CoreModel::VerseBlock.new(
          content: text,
          attribution: node.attribution,
        )
      end

      def build_horizontal_rule
        CoreModel::HorizontalRuleBlock.new
      end

      def build_admonition(node)
        content = build_content(node)
        text = content.map { |c| c.is_a?(CoreModel::InlineElement) ? c.content.to_s : "" }.join

        CoreModel::AnnotationBlock.new(
          annotation_type: node.admonition_type,
          content: text,
        )
      end

      # ── Lists ──

      def build_bullet_list(node)
        items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
        CoreModel::ListBlock.new(
          marker_type: "unordered",
          items: items,
        )
      end

      def build_ordered_list(node)
        items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
        CoreModel::ListBlock.new(
          marker_type: "ordered",
          items: items,
        )
      end

      def build_list_item(node)
        children = build_inline_children(node)
        text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : "" }.join

        nested_list = nil
        node.content&.each do |child|
          next unless child.is_a?(Node)
          if child.type == "bullet_list" || child.type == "ordered_list"
            nested_list = build_node(child)
          end
        end

        CoreModel::ListItem.new(
          content: text,
          children: children.empty? ? children : children,
          nested_list: nested_list,
        )
      end

      def build_definition_list(node)
        terms = []
        descriptions = []
        node.content&.each do |child|
          next unless child.is_a?(Node)
          case child.type
          when "definition_term"
            terms << build_node(child)
          when "definition_description"
            descriptions << build_node(child)
          end
        end

        items = terms.zip(descriptions).map do |term, desc|
          CoreModel::DefinitionItem.new(
            term: term.is_a?(CoreModel::InlineElement) ? term.content : term.to_s,
            definitions: [desc.is_a?(CoreModel::InlineElement) ? desc.content : desc.to_s],
          )
        end

        CoreModel::DefinitionList.new(items: items)
      end

      def build_definition_term(node)
        children = build_inline_children(node)
        text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : "" }.join
        CoreModel::InlineElement.new(content: text)
      end

      def build_definition_description(node)
        children = build_inline_children(node)
        text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : "" }.join
        CoreModel::InlineElement.new(content: text)
      end

      # ── Media ──

      def build_image(node)
        CoreModel::Image.new(
          src: node.src,
          alt: node.alt,
          title: node.title,
          caption: node.caption,
          width: node.width,
          height: node.height,
        )
      end

      # ── Tables ──

      def build_table(node)
        rows = []
        node.content&.each do |child|
          next unless child.is_a?(Node)
          case child.type
          when "table_head", "table_body"
            child.content&.each do |row_node|
              rows << build_node(row_node) if row_node.is_a?(Node)
            end
          end
        end

        CoreModel::Table.new(
          title: node.title,
          rows: rows,
        )
      end

      def build_table_head(node)
        build_content(node).first || CoreModel::TableRow.new
      end

      def build_table_body(node)
        build_content(node).first || CoreModel::TableRow.new
      end

      def build_table_row(node)
        cells = build_content(node).select { |c| c.is_a?(CoreModel::TableCell) }
        CoreModel::TableRow.new(cells: cells)
      end

      def build_table_cell(node)
        text = extract_text(node)
        CoreModel::TableCell.new(
          content: text,
          header: node.header || false,
          colspan: node.colspan,
          rowspan: node.rowspan,
          alignment: node.alignment,
        )
      end

      # ── Bibliography ──

      def build_bibliography(node)
        entries = build_content(node).select { |c| c.is_a?(CoreModel::BibliographyEntry) }
        CoreModel::Bibliography.new(
          title: node.title,
          entries: entries,
        )
      end

      def build_biblio_entry(node)
        text = extract_text(node)
        CoreModel::BibliographyEntry.new(
          anchor_name: node.anchor_name,
          document_id: node.document_id,
          ref_text: text,
        )
      end

      # ── Footnotes ──

      def build_footnote_entry(node)
        text = extract_text(node)
        CoreModel::Footnote.new(
          id: node.id,
          content: text,
        )
      end

      # ── TOC ──

      def build_toc(node)
        CoreModel::Toc.new
      end

      def build_toc_entry(node)
        CoreModel::TocEntry.new(
          id: node.id,
          title: node.title,
        )
      end

      # ── Inline ──

      def build_text(node)
        text = node.text || ""
        marks = node.marks || []

        return CoreModel::TextContent.new(text: text) if marks.empty?

        marks.reduce(CoreModel::TextContent.new(text: text)) do |current, mark|
          apply_mark(current, mark)
        end
      end

      def build_soft_break
        CoreModel::LineBreakElement.new
      end

      # ── Helpers ──

      def apply_mark(inner, mark)
        case mark.type
        when "bold" then CoreModel::BoldElement.new(children: Array(inner))
        when "italic" then CoreModel::ItalicElement.new(children: Array(inner))
        when "code" then CoreModel::MonospaceElement.new(children: Array(inner))
        when "underline" then CoreModel::UnderlineElement.new(children: Array(inner))
        when "strikethrough" then CoreModel::StrikethroughElement.new(children: Array(inner))
        when "subscript" then CoreModel::SubscriptElement.new(children: Array(inner))
        when "superscript" then CoreModel::SuperscriptElement.new(children: Array(inner))
        when "highlight" then CoreModel::HighlightElement.new(children: Array(inner))
        when "link"
          CoreModel::LinkElement.new(
            target: mark.href,
            children: Array(inner),
          )
        when "xref"
          CoreModel::CrossReferenceElement.new(
            target: mark.target,
            children: Array(inner),
          )
        else
          inner
        end
      end

      def build_inline_children(node)
        return [] unless node.content

        node.content.filter_map do |child|
          next unless child.is_a?(Node)
          build_node(child)
        end
      end

      def extract_text(node)
        return node.text.to_s if node.is_a?(Node::Text)
        return "" unless node.content

        node.content.filter_map do |child|
          child.is_a?(Node) ? extract_text(child) : ""
        end.join
      end
    end
  end
end
