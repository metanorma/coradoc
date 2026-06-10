# frozen_string_literal: true

require_relative 'from_core_model_registrations'

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms CoreModel to AsciiDoc models
      class FromCoreModel
        include Coradoc::Transform::Base

        class << self
          def transform(model)
            return model.map { |item| transform(item) } if model.is_a?(Array)
            return model unless model.is_a?(Coradoc::CoreModel::Base)

            transformer = Registry.lookup(model.class)
            transformer ? transformer.call(model) : model
          end

          def transform_structural_element(element)
            case element
            when CoreModel::DocumentElement
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
            when CoreModel::SectionElement
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

            semantic = resolve_semantic_type(block)

            case semantic
            when :paragraph
              return Coradoc::AsciiDoc::Model::Paragraph.new(
                id: block.id,
                content: create_text_elements(content)
              )
            when :comment
              return Coradoc::AsciiDoc::Model::CommentBlock.new(
                text: safe_content_to_string(content)
              )
            end

            content_text = safe_content_to_string(content)

            case semantic
            when :source_code
              Coradoc::AsciiDoc::Model::Block::SourceCode.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n"),
                attributes: build_attributes(block)
              )
            when :quote
              Coradoc::AsciiDoc::Model::Block::Quote.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :example
              Coradoc::AsciiDoc::Model::Block::Example.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :sidebar
              Coradoc::AsciiDoc::Model::Block::Side.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :literal
              Coradoc::AsciiDoc::Model::Block::Literal.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :open
              Coradoc::AsciiDoc::Model::Block::Open.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :pass
              Coradoc::AsciiDoc::Model::Block::Pass.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :listing
              Coradoc::AsciiDoc::Model::Block::Listing.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            when :verse
              Coradoc::AsciiDoc::Model::Block::Quote.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n"),
                delimiter: '[verse]'
              )
            when :reviewer
              Coradoc::AsciiDoc::Model::Block::ReviewerComment.new(
                id: block.id,
                title: block.title,
                lines: content_text.split("\n")
              )
            else
              delim = block.delimiter_type.to_s
              delim_char = delim[0]
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
            case inline.resolve_format_type
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

          def transform_definition_list(definition_list)
            items = Array(definition_list.items).map do |item|
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

          private

          def resolve_semantic_type(block)
            semantic = block.resolve_semantic_type
            return semantic if semantic

            delim = block.delimiter_type
            return nil unless delim && !delim.empty?

            case delim
            when 'comment' then :comment
            when '[verse]' then :verse
            when '>' then :quote
            when "'''", '---', '___', '***' then :horizontal_rule
            else
              char = delim[0]
              DelimiterMapping::CHAR_TO_SEMANTIC[char] || nil
            end
          end

          def safe_content_to_string(content)
            case content
            when String
              content
            when Array
              content.map { |item| safe_content_to_string(item) }.join
            when Lutaml::Model::Serializable
              if content.is_a?(Coradoc::AsciiDoc::Model::Base)
                content.to_adoc
              elsif content.class.attributes.key?(:text)
                content.text.to_s
              else
                ''
              end
            when nil
              ''
            else
              content.is_a?(String) ? content : ''
            end
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
              text = if content.is_a?(Coradoc::AsciiDoc::Model::Base)
                       content.to_adoc
                     elsif content.class.attributes.key?(:text)
                       content.text.to_s
                     else
                       ''
                     end
              Coradoc::AsciiDoc::Model::TextElement.new(content: text)
            when String
              Coradoc::AsciiDoc::Model::TextElement.new(content: content)
            else
              text = content.is_a?(String) ? content : ''
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
