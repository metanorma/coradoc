# frozen_string_literal: true

require_relative 'reverse_builder'

# One Builder class per Mirror node type. Each class is self-contained
# and self-registers its type strings via `registers` (OCP). Adding a
# new type = appending a new class here — no edit to MirrorToCoreModel.
module Coradoc
  module Mirror
    module ReverseBuilder
      # ── Structural ──

      class Document < Base
        registers 'doc'

        def build(node)
          CoreModel::DocumentElement.new(
            title: node.title,
            id: node.id,
            children: build_content(node)
          )
        end
      end

      # All JS SECTION_TYPES reverse to a generic SectionElement. Style
      # information lives in the original AsciiDoc and is preserved only
      # on the forward side; the reverse side collapses them.
      class Section < Base
        registers 'section', 'clause', 'annex', 'content_section',
                  'abstract', 'foreword', 'introduction',
                  'acknowledgements', 'terms', 'definitions', 'references'

        def build(node)
          CoreModel::SectionElement.new(
            title: node.title,
            level: node.level,
            id: node.id,
            children: build_content(node)
          )
        end
      end

      class Header < Base
        registers 'floating_title', 'heading'

        def build(node)
          CoreModel::HeaderElement.new(
            title: node.title,
            level: node.level,
            children: build_content(node)
          )
        end
      end

      class Preamble < Base
        registers 'preface'

        def build(node)
          CoreModel::PreambleElement.new(children: build_content(node))
        end
      end

      # `sections` is a structural container only — unwrap directly into
      # an array. MirrorToCoreModel#build_content flattens arrays.
      class Sections < Base
        registers 'sections'

        def build(node)
          build_content(node)
        end
      end

      # ── Blocks ──

      class Paragraph < Base
        registers 'paragraph'

        def build(node)
          CoreModel::ParagraphBlock.new(children: build_inline_children(node))
        end
      end

      class CodeBlock < Base
        registers 'sourcecode'

        def build(node)
          CoreModel::SourceBlock.new(
            content: node.text || extract_text(node),
            language: node.language,
            title: node.title
          )
        end
      end

      class Blockquote < Base
        registers 'quote'

        def build(node)
          CoreModel::QuoteBlock.new(
            attribution: node.attribution,
            children: build_content(node)
          )
        end
      end

      class Example < Base
        registers 'example'

        def build(node)
          CoreModel::ExampleBlock.new(
            title: node.title,
            children: build_content(node)
          )
        end
      end

      class Sidebar < Base
        registers 'sidebar'

        def build(node)
          CoreModel::SidebarBlock.new(
            title: node.title,
            children: build_content(node)
          )
        end
      end

      class OpenBlock < Base
        registers 'open_block'

        def build(node)
          CoreModel::OpenBlock.new(children: build_content(node))
        end
      end

      class Verse < Base
        registers 'verse'

        def build(node)
          CoreModel::VerseBlock.new(
            content: extract_text(node),
            attribution: node.attribution
          )
        end
      end

      class HorizontalRule < Base
        registers 'horizontal_rule', 'thematic_break'

        def build(_node)
          CoreModel::HorizontalRuleBlock.new
        end
      end

      class Frontmatter < Base
        registers 'frontmatter'

        def build(node)
          CoreModel::FrontmatterBlock.new(
            schema: node.schema,
            data: node.data || {}
          )
        end
      end

      class Admonition < Base
        registers 'admonition'

        def build(node)
          CoreModel::AnnotationBlock.new(
            annotation_type: node.admonition_type,
            content: extract_text(node)
          )
        end
      end

      # ── Lists ──

      class BulletList < Base
        registers 'bullet_list'

        def build(node)
          items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
          CoreModel::ListBlock.new(marker_type: 'unordered', items: items)
        end
      end

      class OrderedList < Base
        registers 'ordered_list'

        def build(node)
          items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
          CoreModel::ListBlock.new(marker_type: 'ordered', items: items)
        end
      end

      class ListItem < Base
        registers 'list_item'

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join

          CoreModel::ListItem.new(
            content: text,
            children: children,
            nested_list: find_nested_list(node)
          )
        end

        private

        def find_nested_list(node)
          node.content&.each do |child|
            next unless child.is_a?(Node)
            return build_node(child) if LIST_TYPES.include?(child.type)
          end
          nil
        end
      end

      class DefinitionList < Base
        registers 'dl'

        def build(node)
          terms = []
          descriptions = []
          node.content&.each do |child|
            next unless child.is_a?(Node)

            case child.type
            when 'dt' then terms << build_node(child)
            when 'dd' then descriptions << build_node(child)
            end
          end

          items = terms.zip(descriptions).map do |term, desc|
            CoreModel::DefinitionItem.new(
              term: inline_content(term),
              definitions: [inline_content(desc)]
            )
          end

          CoreModel::DefinitionList.new(items: items)
        end
      end

      class InlineText < Base
        registers 'dt', 'dd'

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join
          CoreModel::InlineElement.new(content: text)
        end
      end

      # ── Media ──

      class Image < Base
        registers 'image'

        def build(node)
          CoreModel::Image.new(
            src: node.src,
            alt: node.alt,
            title: node.title,
            caption: node.caption,
            width: node.width,
            height: node.height
          )
        end
      end

      # JS @metanorma/mirror `figure` wraps an image plus an optional
      # caption. Reverse: collapse back to a single CoreModel::Image,
      # promoting the caption child to `caption:` if present.
      class Figure < Base
        registers 'figure'

        def build(node)
          image_child = node.content&.find { |c| c.is_a?(Node) && c.type == 'image' }
          return nil unless image_child

          image = build_node(image_child)
          caption = extract_caption(node)
          image.caption = caption if caption && !image.caption
          image
        end

        private

        def extract_caption(node)
          caption_node = node.content&.find { |c| c.is_a?(Node) && c.type == 'caption' }
          return nil unless caption_node

          extract_text(caption_node)
        end
      end

      # Caption only appears as a Figure child. If encountered standalone,
      # extract its text as an inline element so it isn't lost.
      class Caption < Base
        registers 'caption'

        def build(node)
          CoreModel::InlineElement.new(content: extract_text(node))
        end
      end

      # ── Tables ──

      class Table < Base
        registers 'table'

        def build(node)
          rows = []
          node.content&.each do |child|
            next unless child.is_a?(Node)
            next unless %w[table_head table_body].include?(child.type)

            child.content&.each do |row_node|
              rows << build_node(row_node) if row_node.is_a?(Node)
            end
          end

          CoreModel::Table.new(title: node.title, rows: rows)
        end
      end

      class TableHead < Base
        registers 'table_head'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end

      class TableBody < Base
        registers 'table_body'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end

      class TableRow < Base
        registers 'table_row'

        def build(node)
          cells = build_content(node).select { |c| c.is_a?(CoreModel::TableCell) }
          CoreModel::TableRow.new(cells: cells)
        end
      end

      class TableCell < Base
        registers 'table_cell'

        def build(node)
          CoreModel::TableCell.new(
            content: extract_text(node),
            header: node.header || false,
            colspan: node.colspan,
            rowspan: node.rowspan,
            alignment: node.alignment
          )
        end
      end

      # ── Bibliography ──

      class Bibliography < Base
        registers 'bibliography'

        def build(node)
          entries = build_content(node).select { |c| c.is_a?(CoreModel::BibliographyEntry) }
          CoreModel::Bibliography.new(title: node.title, entries: entries)
        end
      end

      class BiblioEntry < Base
        registers 'biblio_entry'

        def build(node)
          CoreModel::BibliographyEntry.new(
            anchor_name: node.anchor_name,
            document_id: node.document_id,
            ref_text: extract_text(node)
          )
        end
      end

      # ── Footnotes ──

      # The `footnotes` block is a structural trailing container; it has
      # no CoreModel equivalent (each entry is built separately). Returns
      # nil so build_content filters it out.
      class Footnotes < Base
        registers 'footnotes'

        def build(_node)
          nil
        end
      end

      class FootnoteEntry < Base
        registers 'footnote_entry'

        def build(node)
          CoreModel::Footnote.new(id: node.id, content: extract_text(node))
        end
      end

      # Inline footnote marker (JS `footnote_marker`). The CoreModel
      # FootnoteReference holds the same id/ref/number triple.
      class FootnoteMarker < Base
        registers 'footnote_marker'

        def build(node)
          CoreModel::FootnoteReference.new(
            id: node.id,
            reference: node.ref_id,
            number: node.number
          )
        end
      end

      # ── TOC ──

      class Toc < Base
        registers 'toc'

        def build(_node)
          CoreModel::Toc.new
        end
      end

      class TocEntry < Base
        registers 'toc_entry'

        def build(node)
          CoreModel::TocEntry.new(id: node.id, title: node.title)
        end
      end

      # ── Inline ──

      class Text < Base
        registers 'text'

        def build(node)
          text = node.text || ''
          marks = node.marks || []

          return CoreModel::TextContent.new(text: text) if marks.empty?

          marks.reduce(CoreModel::TextContent.new(text: text)) do |current, mark|
            apply_mark(current, mark)
          end
        end
      end

      class SoftBreak < Base
        registers 'soft_break'

        def build(_node)
          CoreModel::LineBreakElement.new
        end
      end

      # Catch-all for unrecognized block types emitted by the forward
      # direction (`Node::GenericBlock`). Preserves the semantic_type so
      # downstream consumers can dispatch on it.
      class GenericBlock < Base
        registers 'generic_block'

        def build(node)
          CoreModel::Block.new(
            block_semantic_type: node.semantic_type || 'generic',
            title: node.title,
            id: node.id,
            content: extract_text(node)
          )
        end
      end

      LIST_TYPES = %w[bullet_list ordered_list].freeze
      private_constant :LIST_TYPES
    end
  end
end
