# frozen_string_literal: true

require_relative 'to_core_model_registrations'

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms AsciiDoc models to CoreModel equivalents
      class ToCoreModel
        def transform(model)
          self.class.transform(model)
        end

        class << self
          def transform(model)
            return model.map { |item| transform(item) }.compact if model.is_a?(Array)
            return model unless model.is_a?(Coradoc::AsciiDoc::Model::Base)

            transformer = Registry.lookup(model.class)
            return transformer.call(model) if transformer

            transform_with_case(model)
          end

          def transform_with_case(model)
            case model
            when Coradoc::AsciiDoc::Model::Document
              transform_document(model)
            when Coradoc::AsciiDoc::Model::Section
              transform_section(model)
            when Coradoc::AsciiDoc::Model::Paragraph
              transform_paragraph(model)
            when Coradoc::AsciiDoc::Model::Block::SourceCode
              transform_block(model, 'source')
            when Coradoc::AsciiDoc::Model::Block::Quote
              transform_block(model, 'quote')
            when Coradoc::AsciiDoc::Model::Block::Example
              transform_block(model, 'example')
            when Coradoc::AsciiDoc::Model::Block::Side
              transform_block(model, 'sidebar')
            when Coradoc::AsciiDoc::Model::Block::Literal
              transform_block(model, 'literal')
            when Coradoc::AsciiDoc::Model::Block::Open
              transform_block(model, 'open')
            when Coradoc::AsciiDoc::Model::Block::Pass
              transform_block(model, 'pass')
            when Coradoc::AsciiDoc::Model::Block::Core
              transform_block(model, model.delimiter)
            when Coradoc::AsciiDoc::Model::Table
              transform_table(model)
            when Coradoc::AsciiDoc::Model::TableRow
              transform_table_row(model)
            when Coradoc::AsciiDoc::Model::TableCell
              transform_table_cell(model)
            when Coradoc::AsciiDoc::Model::List::Unordered
              transform_list(model, 'unordered')
            when Coradoc::AsciiDoc::Model::List::Ordered
              transform_list(model, 'ordered')
            when Coradoc::AsciiDoc::Model::List::Definition
              transform_list(model, 'definition')
            when Coradoc::AsciiDoc::Model::Term
              transform_term(model)
            when Coradoc::AsciiDoc::Model::Admonition
              transform_admonition(model)
            when Coradoc::AsciiDoc::Model::Inline::Bold
              transform_inline(model, 'bold')
            when Coradoc::AsciiDoc::Model::Inline::Italic
              transform_inline(model, 'italic')
            when Coradoc::AsciiDoc::Model::Inline::Monospace
              transform_inline(model, 'monospace')
            when Coradoc::AsciiDoc::Model::Inline::Highlight
              transform_inline(model, 'highlight')
            when Coradoc::AsciiDoc::Model::Inline::Link
              transform_link(model)
            when Coradoc::AsciiDoc::Model::Inline::CrossReference
              transform_cross_reference(model)
            when Coradoc::AsciiDoc::Model::Inline::Stem
              transform_stem(model)
            when Coradoc::AsciiDoc::Model::CommentBlock
              Coradoc::CoreModel::Block.new(
                element_type: 'comment',
                content: model.text.to_s
              )
            when Coradoc::AsciiDoc::Model::Bibliography
              transform_bibliography(model)
            when Coradoc::AsciiDoc::Model::BibliographyEntry
              transform_bibliography_entry(model)
            when Coradoc::AsciiDoc::Model::Image::BlockImage
              transform_image(model)
            when Coradoc::AsciiDoc::Model::TextElement
              extract_text_content(model)
            else
              model
            end
          end

          def transform_document(doc)
            title_text = extract_title_text(doc.header&.title)
            attributes = extract_document_attributes(doc)
            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              id: doc.id,
              title: title_text,
              attributes: attributes,
              children: transform(doc.sections || doc.contents || [])
            )
          end

          def transform_section(section)
            title_text = extract_title_text(section.title)
            content_children = transform(section.contents || [])
            nested_sections = transform(section.sections || [])

            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'section',
              id: section.id,
              level: section.level,
              title: title_text,
              children: content_children + nested_sections
            )
          end

          def transform_paragraph(para)
            children = transform_inline_content(para.content)

            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              id: para.id,
              content: extract_text_content(para.content),
              children: children
            )
          end

          def transform_block(block, delimiter_type)
            content_lines = Array(block.lines).map do |line|
              case line
              when Coradoc::AsciiDoc::Model::Base
                transformed = transform(line)
                if transformed.is_a?(Coradoc::CoreModel::Base)
                  extract_core_model_text(transformed)
                else
                  transformed.to_s
                end
              else
                line.to_s
              end
            end.join("\n")

            language = block.lang || block.attributes&.[]('language') ||
                       block.attributes&.positional&.first

            Coradoc::CoreModel::Block.new(
              element_type: 'block',
              delimiter_type: delimiter_type,
              id: block.id,
              title: extract_title_text(block.title),
              content: content_lines,
              language: language
            )
          end

          def transform_table(table)
            rows = Array(table.rows).map do |row|
              transform_table_row(row)
            end

            Coradoc::CoreModel::Table.new(
              id: table.id,
              title: table.title&.to_s,
              rows: rows
            )
          end

          def transform_table_row(row)
            cells = Array(row.columns).map do |cell|
              transform_table_cell(cell)
            end
            Coradoc::CoreModel::TableRow.new(
              cells: cells,
              header: row.header
            )
          end

          def transform_table_cell(cell)
            children = transform_inline_content(cell.content)

            Coradoc::CoreModel::TableCell.new(
              content: extract_text_content(cell.content),
              alignment: cell.horizontal_alignment,
              vertical_alignment: cell.vertical_alignment,
              colspan: cell.colspan,
              rowspan: cell.rowspan,
              style: cell.style_name,
              children: children
            )
          end

          def transform_list(list, marker_type)
            items = Array(list.items).map do |item|
              if item.is_a?(Coradoc::AsciiDoc::Model::List::DefinitionItem)
                term_content = item.terms
                def_content = item.contents

                Coradoc::CoreModel::DefinitionItem.new(
                  term: extract_text_content(term_content),
                  definitions: [extract_text_content(def_content)]
                )
              else
                content_val = item.content
                children = transform_inline_content(content_val)

                li = Coradoc::CoreModel::ListItem.new(
                  content: extract_text_content(content_val),
                  marker: item.marker
                )
                li.children = children
                li
              end
            end

            if marker_type == 'definition'
              Coradoc::CoreModel::DefinitionList.new(items: items)
            else
              Coradoc::CoreModel::ListBlock.new(
                marker_type: marker_type,
                items: items
              )
            end
          end

          def transform_term(term)
            Coradoc::CoreModel::Term.new(
              text: term.term.to_s,
              type: term.type&.to_s || 'preferred',
              lang: term.lang&.to_s || 'en'
            )
          end

          def transform_admonition(admonition)
            Coradoc::CoreModel::AnnotationBlock.new(
              annotation_type: admonition.type,
              content: extract_text_content(admonition.content)
            )
          end

          def transform_inline(inline, format_type)
            Coradoc::CoreModel::InlineElement.new(
              format_type: format_type,
              content: extract_text_content(inline.content)
            )
          end

          def transform_inline_text(inline, format_type)
            Coradoc::CoreModel::InlineElement.new(
              format_type: format_type,
              content: inline.text.to_s
            )
          end

          def transform_inline_footnote(footnote)
            parsed_content = parse_and_transform_inline(footnote.text.to_s)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'footnote',
              target: footnote.id,
              content: parsed_content
            )
          end

          def transform_link(link)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'link',
              target: link.path,
              content: link.name || link.path
            )
          end

          def transform_cross_reference(xref)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'xref',
              target: xref.href,
              content: xref.args&.first || xref.href
            )
          end

          def transform_stem(stem)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'stem',
              content: stem.content,
              stem_type: stem.type || 'stem'
            )
          end

          def transform_image(image)
            Coradoc::CoreModel::Image.new(
              src: image.src,
              alt: image.title&.to_s,
              width: image.attributes&.[]('width'),
              height: image.attributes&.[]('height')
            )
          end

          def transform_bibliography(bib)
            entries = Array(bib.entries).map do |entry|
              transform_bibliography_entry(entry)
            end

            Coradoc::CoreModel::Bibliography.new(
              id: bib.id,
              title: bib.title.to_s,
              level: nil,
              entries: entries
            )
          end

          def transform_bibliography_entry(entry)
            Coradoc::CoreModel::BibliographyEntry.new(
              anchor_name: entry.anchor_name,
              document_id: entry.document_id,
              ref_text: entry.ref_text.to_s
            )
          end

          private

          def extract_document_attributes(doc)
            return {} unless doc.document_attributes
            doc.document_attributes.to_hash
          end

          def transform_inline_content(content)
            return [] if content.nil?

            case content
            when Array
              content.flat_map { |item| transform_inline_content(item) }
            when Coradoc::AsciiDoc::Model::TextElement
              transform_inline_content(content.content)
            when Coradoc::AsciiDoc::Model::Term
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'term',
                content: content.term.to_s
              )]
            when String
              content.empty? ? [] : [content]
            when Coradoc::AsciiDoc::Model::Base
              [transform(content)]
            else
              text = extract_text_content(content)
              text.empty? ? [] : [text]
            end
          end

          def extract_core_model_text(model)
            case model
            when Coradoc::CoreModel::ListBlock
              model.items.map do |item|
                item.is_a?(Coradoc::CoreModel::ListItem) ? "* #{item.flat_text}" : item.to_s
              end.join("\n")
            when Coradoc::CoreModel::AnnotationBlock
              "#{model.annotation_type}: #{model.flat_text}"
            when Coradoc::CoreModel::Block
              model.flat_text
            when Coradoc::CoreModel::Image
              model.alt || ''
            when Coradoc::CoreModel::InlineElement
              model.content.to_s
            else
              ''
            end
          end

          def extract_title_text(title)
            return nil if title.nil?
            return title.to_s unless title.is_a?(Coradoc::AsciiDoc::Model::Title)

            content = title.content
            return '' if content.nil?

            if content.is_a?(String)
              content
            elsif content.is_a?(Array)
              content.map { |c| extract_text_content(c) }.join
            else
              extract_text_content(content)
            end
          end

          def extract_text_content(content)
            case content
            when nil
              ''
            when String
              content
            when Array
              result = []
              content.each_with_index do |item, idx|
                text = extract_text_content(item)
                result << text if text && !text.empty?

                next unless idx < content.length - 1 && text && !text.empty?

                result << ' ' if item.is_a?(Coradoc::AsciiDoc::Model::TextElement) && item.line_break != '+'
              end
              result.join
            when Coradoc::AsciiDoc::Model::TextElement
              if content.content.is_a?(Array)
                extract_text_content(content.content)
              else
                content.content.to_s
              end
            when Coradoc::AsciiDoc::Model::Inline::Bold,
                 Coradoc::AsciiDoc::Model::Inline::Italic,
                 Coradoc::AsciiDoc::Model::Inline::Monospace,
                 Coradoc::AsciiDoc::Model::Inline::Highlight,
                 Coradoc::AsciiDoc::Model::Inline::Strikethrough,
                 Coradoc::AsciiDoc::Model::Inline::Subscript,
                 Coradoc::AsciiDoc::Model::Inline::Superscript,
                 Coradoc::AsciiDoc::Model::Inline::Underline
              extract_text_content(content.content)
            when Coradoc::AsciiDoc::Model::Inline::Link
              content.name || content.path || ''
            when Coradoc::AsciiDoc::Model::Inline::CrossReference
              content.href || ''
            when Coradoc::AsciiDoc::Model::Inline::Stem
              content.content.to_s
            when Coradoc::AsciiDoc::Model::Inline::Footnote
              if content.content
                extract_text_content(content.content)
              else
                ''
              end
            when Coradoc::AsciiDoc::Model::Inline::AttributeReference
              "{#{content.name}}"
            when Coradoc::AsciiDoc::Model::Term
              content.term.to_s
            when Coradoc::CoreModel::Image
              content.alt || content.src || ''
            when Coradoc::AsciiDoc::Model::Base
              if content.content
                extract_text_content(content.content)
              else
                ''
              end
            else
              if content.is_a?(String)
                content
              elsif content.class.name.start_with?('Parslet::')
                content.to_s
              else
                ''
              end
            end
          end

          def parse_and_transform_inline(text)
            return text if text.nil? || text.to_s.strip.empty?

            inline_patterns = [
              /stem:\[/,
              /term:\[/,
              /footnote:\[/,
              /\{[a-zA-Z_]+\}/,
              %r{https?://},
              /<[^>]+>/
            ]

            has_inline_markup = inline_patterns.any? { |pattern| text =~ pattern }
            return text unless has_inline_markup

            begin
              parsed_elements = Coradoc::AsciiDoc::Transformer.parse_inline_content(text)
              content_array = parsed_elements.flat_map do |element|
                if element.is_a?(Coradoc::AsciiDoc::Model::TextElement)
                  element.content
                else
                  element
                end
              end

              transformed = transform_inline_content(content_array)

              if transformed.all? { |item| item.is_a?(String) }
                transformed.join
              else
                transformed
              end
            rescue StandardError
              text
            end
          end
        end
      end
    end
  end
end
