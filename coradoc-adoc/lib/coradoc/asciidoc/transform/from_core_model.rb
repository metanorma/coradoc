# frozen_string_literal: true

require_relative 'from_core_model_registrations'

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms CoreModel to AsciiDoc models
      class FromCoreModel
        def transform(model)
          self.class.transform(model)
        end

        class << self
          def transform(model)
            return model.map { |item| transform(item) } if model.is_a?(Array)
            return model unless model.is_a?(Coradoc::CoreModel::Base)

            transformer = Registry.lookup(model.class)
            return transformer.call(model) if transformer

            transform_with_case(model)
          end

          def transform_with_case(model)
            case model
            when Coradoc::CoreModel::StructuralElement
              transform_structural_element(model)
            when Coradoc::CoreModel::AnnotationBlock
              transform_annotation(model)
            when Coradoc::CoreModel::Block
              transform_block(model)
            when Coradoc::CoreModel::Table
              transform_table(model)
            when Coradoc::CoreModel::ListBlock
              transform_list(model)
            when Coradoc::CoreModel::ListItem
              transform_list_item(model)
            when Coradoc::CoreModel::Term
              transform_term(model)
            when Coradoc::CoreModel::InlineElement
              transform_inline(model)
            when Coradoc::CoreModel::Image
              transform_image(model)
            when Coradoc::CoreModel::Footnote
              transform_footnote(model)
            when Coradoc::CoreModel::FootnoteReference
              transform_footnote_reference(model)
            when Coradoc::CoreModel::Abbreviation
              transform_abbreviation(model)
            when Coradoc::CoreModel::DefinitionList
              transform_definition_list(model)
            when Coradoc::CoreModel::DefinitionItem
              transform_definition_item(model)
            when Coradoc::CoreModel::Toc
              transform_toc(model)
            when Coradoc::CoreModel::TocEntry
              transform_toc_entry(model)
            when Coradoc::CoreModel::Bibliography
              transform_bibliography(model)
            when Coradoc::CoreModel::BibliographyEntry
              transform_bibliography_entry(model)
            else
              model
            end
          end

          private

          def transform_structural_element(element)
            case element.element_type
            when 'document'
              header = if element.title
                         Coradoc::AsciiDoc::Model::Header.new(
                           title: Coradoc::AsciiDoc::Model::Title.new(
                             content: element.title,
                             level_int: 0
                           )
                         )
                       else
                         Coradoc::AsciiDoc::Model::Header.new(title: '')
                       end

              Coradoc::AsciiDoc::Model::Document.new(
                id: element.id,
                header: header,
                sections: transform(element.children)
              )
            when 'section'
              Coradoc::AsciiDoc::Model::Section.new(
                id: element.id,
                level: element.level,
                title: create_title(element.title, element.level),
                contents: transform(element.children)
              )
            else
              Coradoc::AsciiDoc::Model::Section.new(
                id: element.id,
                title: create_title(element.title, 1),
                contents: transform(element.children)
              )
            end
          end

          def transform_block(block)
            content = block.renderable_content

            if block.element_type == 'paragraph'
              return Coradoc::AsciiDoc::Model::Paragraph.new(
                id: block.id,
                content: create_text_elements(content)
              )
            end

            if block.element_type == 'comment'
              return Coradoc::AsciiDoc::Model::CommentBlock.new(
                text: safe_content_to_string(content)
              )
            end

            content_text = safe_content_to_string(content)

            case block.delimiter_type
            when 'source'
              Coradoc::AsciiDoc::Model::Block::SourceCode.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n"),
                attributes: build_attributes(block)
              )
            when 'quote'
              Coradoc::AsciiDoc::Model::Block::Quote.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when 'example'
              Coradoc::AsciiDoc::Model::Block::Example.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when 'sidebar'
              Coradoc::AsciiDoc::Model::Block::Side.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when 'literal'
              Coradoc::AsciiDoc::Model::Block::Literal.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when 'paragraph'
              Coradoc::AsciiDoc::Model::Paragraph.new(
                id: block.id,
                content: create_text_elements(content)
              )
            else
              delim = block.delimiter_type.to_s
              delim_char = delim.chars.first
              delim_len = delim.length

              Coradoc::AsciiDoc::Model::Block::Core.new(
                id: block.id,
                title: block.title,
                delimiter: delim,
                delimiter_char: delim_char,
                delimiter_len: delim_len,
                lines: content_text.split("\n")
              )
            end
          end

          def safe_content_to_string(content)
            case content
            when String
              content
            when Array
              content.map { |item| safe_content_to_string(item) }.join
            when Lutaml::Model::Serializable
              if content.respond_to?(:to_adoc)
                content.to_adoc
              elsif content.respond_to?(:text)
                content.text.to_s
              elsif content.respond_to?(:content)
                safe_content_to_string(content.content)
              else
                ''
              end
            when nil
              ''
            else
              content.respond_to?(:to_str) ? content.to_s : ''
            end
          end

          def transform_table(table)
            rows = Array(table.rows).map do |row|
              columns = Array(row.cells).map do |cell|
                Coradoc::AsciiDoc::Model::TableCell.new(
                  content: cell.flat_text
                )
              end
              Coradoc::AsciiDoc::Model::TableRow.new(
                columns: columns
              )
            end

            Coradoc::AsciiDoc::Model::Table.new(
              id: table.id,
              title: table.title,
              rows: rows
            )
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              Coradoc::AsciiDoc::Model::List::Item.new(
                content: item.flat_text,
                marker: item.marker || default_marker(list.marker_type)
              )
            end

            case list.marker_type
            when 'ordered'
              Coradoc::AsciiDoc::Model::List::Ordered.new(items: items)
            when 'definition'
              Coradoc::AsciiDoc::Model::List::Definition.new(items: items)
            else
              Coradoc::AsciiDoc::Model::List::Unordered.new(items: items)
            end
          end

          def transform_list_item(item)
            Coradoc::AsciiDoc::Model::List::Item.new(
              content: item.flat_text,
              marker: item.marker
            )
          end

          def transform_term(term)
            Coradoc::AsciiDoc::Model::Term.new(
              term: term.text,
              type: term.type&.to_s || 'preferred',
              lang: term.lang || 'en'
            )
          end

          def transform_annotation(annotation)
            Coradoc::AsciiDoc::Model::Admonition.new(
              type: annotation.annotation_type.to_s.upcase,
              content: create_text_elements(annotation.renderable_content)
            )
          end

          def transform_inline(inline)
            case inline.format_type
            when 'bold'
              Coradoc::AsciiDoc::Model::Inline::Bold.new(content: inline.content)
            when 'italic'
              Coradoc::AsciiDoc::Model::Inline::Italic.new(content: inline.content)
            when 'monospace'
              Coradoc::AsciiDoc::Model::Inline::Monospace.new(content: inline.content)
            when 'highlight'
              Coradoc::AsciiDoc::Model::Inline::Highlight.new(content: inline.content)
            when 'strikethrough'
              Coradoc::AsciiDoc::Model::Inline::Strikethrough.new(content: inline.content)
            when 'subscript'
              Coradoc::AsciiDoc::Model::Inline::Subscript.new(content: inline.content)
            when 'superscript'
              Coradoc::AsciiDoc::Model::Inline::Superscript.new(content: inline.content)
            when 'underline'
              Coradoc::AsciiDoc::Model::Inline::Underline.new(text: inline.content)
            when 'link'
              Coradoc::AsciiDoc::Model::Inline::Link.new(
                path: inline.target,
                name: inline.content
              )
            when 'xref'
              Coradoc::AsciiDoc::Model::Inline::CrossReference.new(href: inline.target)
            when 'footnote'
              Coradoc::AsciiDoc::Model::Inline::Footnote.new(
                id: inline.target,
                text: inline.content
              )
            when 'stem'
              Coradoc::AsciiDoc::Model::Inline::Stem.new(
                type: inline.stem_type || 'latexmath',
                content: inline.content
              )
            else
              Coradoc::AsciiDoc::Model::TextElement.new(content: inline.content)
            end
          end

          def transform_image(image)
            Coradoc::AsciiDoc::Model::Image::BlockImage.new(
              src: image.src,
              title: image.alt,
              attributes: build_image_attributes(image)
            )
          end

          def transform_bibliography(bib)
            entries = Array(bib.entries).map do |entry|
              transform_bibliography_entry(entry)
            end

            Coradoc::AsciiDoc::Model::Bibliography.new(
              id: bib.id,
              title: bib.title,
              entries: entries
            )
          end

          def transform_bibliography_entry(entry)
            Coradoc::AsciiDoc::Model::BibliographyEntry.new(
              anchor_name: entry.anchor_name,
              document_id: entry.document_id,
              ref_text: entry.ref_text
            )
          end

          def transform_footnote(footnote)
            Coradoc::AsciiDoc::Model::Inline::Footnote.new(
              id: footnote.id,
              text: footnote.content.to_s
            )
          end

          def transform_footnote_reference(footnote_ref)
            Coradoc::AsciiDoc::Model::Inline::Footnote.new(
              id: footnote_ref.id
            )
          end

          def transform_abbreviation(abbreviation)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: abbreviation.term.to_s +
                       (abbreviation.definition ? " (#{abbreviation.definition})" : '')
            )
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |item|
              transform_definition_item(item)
            end
            Coradoc::AsciiDoc::Model::List::Definition.new(items: items)
          end

          def transform_definition_item(item)
            term = Coradoc::AsciiDoc::Model::Term.new(term: item.term.to_s)
            contents = Array(item.definitions).map do |defn|
              Coradoc::AsciiDoc::Model::TextElement.new(content: defn.to_s)
            end
            Coradoc::AsciiDoc::Model::List::DefinitionItem.new(
              terms: [term],
              contents: contents
            )
          end

          def transform_toc(_toc)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: 'toc::[]'
            )
          end

          def transform_toc_entry(entry)
            Coradoc::AsciiDoc::Model::TextElement.new(
              content: entry.title.to_s
            )
          end

          def create_title(text, level)
            return nil if text.nil?

            Coradoc::AsciiDoc::Model::Title.new(
              content: text,
              level_int: level || 1
            )
          end

          def create_text_elements(content)
            case content
            when Array
              content.map { |item| create_text_elements(item) }
            when Coradoc::CoreModel::InlineElement
              transform_inline(content)
            when Coradoc::AsciiDoc::Model::Base
              content
            when Lutaml::Model::Serializable
              text = if content.respond_to?(:to_adoc)
                       content.to_adoc
                     elsif content.respond_to?(:text)
                       content.text.to_s
                     elsif content.respond_to?(:content)
                       content.content.to_s
                     else
                       ''
                     end
              Coradoc::AsciiDoc::Model::TextElement.new(content: text)
            when String
              Coradoc::AsciiDoc::Model::TextElement.new(content: content)
            else
              text = if content.respond_to?(:to_str)
                       content.to_s
                     else
                       ''
                     end
              Coradoc::AsciiDoc::Model::TextElement.new(content: text)
            end
          end

          def build_attributes(block)
            attrs = {}
            attrs['language'] = block.language if block.language
            attrs
          end

          def build_image_attributes(image)
            attrs = {}
            attrs['width'] = image.width if image.width
            attrs['height'] = image.height if image.height
            attrs
          end

          def default_marker(marker_type)
            case marker_type
            when 'ordered' then '.'
            else '*'
            end
          end
        end
      end
    end
  end
end
