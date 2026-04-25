# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms CoreModel to AsciiDoc models
      #
      # This transformer converts the canonical CoreModel representation
      # to format-specific AsciiDoc model.
      class FromCoreModel
        # Instance method that delegates to class method for convenience
        def transform(model)
          self.class.transform(model)
        end

        class << self
          # Transform a CoreModel to AsciiDoc model
          #
          # First checks the Registry for a registered transformer.
          # If none found, falls back to the case statement implementation.
          #
          # @param model [Coradoc::CoreModel::Base] CoreModel to transform
          # @return [Coradoc::AsciiDoc::Model::Base] AsciiDoc model equivalent
          def transform(model)
            # Check if there's a registered transformer
            transformer = Registry.lookup(model.class) if model.is_a?(Coradoc::CoreModel::Base)

            if transformer
              transformer.call(model)
            else
              # Fall back to case statement for unregistered types
              transform_with_case(model)
            end
          end

          # Transform using case statement (used as fallback when no registered transformer)
          #
          # This method handles all built-in types and can be used directly
          # if you want to bypass the registry.
          #
          # @api private
          def transform_with_case(model)
            case model
            when Coradoc::CoreModel::StructuralElement
              transform_structural_element(model)
            when Coradoc::CoreModel::AnnotationBlock
              # Must be checked before Block since AnnotationBlock < Block
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
            when Array
              model.map { |item| transform(item) }
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
              # Generic structural element
              Coradoc::AsciiDoc::Model::Section.new(
                id: element.id,
                title: create_title(element.title, 1),
                contents: transform(element.children)
              )
            end
          end

          def transform_block(block)
            # Use renderable_content which returns children if present, else content
            content = block.renderable_content

            # Check element_type first for paragraphs (which don't have delimiter_type)
            if block.element_type == 'paragraph'
              return Coradoc::AsciiDoc::Model::Paragraph.new(
                id: block.id,
                content: create_text_elements(content)
              )
            end

            # Handle comment blocks
            if block.element_type == 'comment'
              return Coradoc::AsciiDoc::Model::CommentBlock.new(
                text: safe_content_to_string(content)
              )
            end

            # Safely extract text content for blocks that need lines
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
              # Generic block - use delimiter directly (for ====. ----, etc.)
              # Compute delimiter_char and delimiter_len from delimiter_type
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

          # Safely convert content to string without producing Ruby object dumps
          def safe_content_to_string(content)
            case content
            when String
              content
            when Array
              content.map { |item| safe_content_to_string(item) }.join
            when Lutaml::Model::Serializable
              # Handle Lutaml models - try to extract text properly
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
              # Only use to_s for simple types that respond to to_str
              content.respond_to?(:to_str) ? content.to_s : ''
            end
          end

          def transform_table(table)
            rows = Array(table.rows).map do |row|
              columns = Array(row.cells).map do |cell|
                Coradoc::AsciiDoc::Model::TableCell.new(
                  content: cell.content
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
                content: item.content,
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
              content: item.content,
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
              content: create_text_elements(annotation.content)
            )
          end

          def transform_inline(inline)
            case inline.format_type
            when 'bold'
              Coradoc::AsciiDoc::Model::Inline::Bold.new(
                content: inline.content
              )
            when 'italic'
              Coradoc::AsciiDoc::Model::Inline::Italic.new(
                content: inline.content
              )
            when 'monospace'
              Coradoc::AsciiDoc::Model::Inline::Monospace.new(
                content: inline.content
              )
            when 'highlight'
              Coradoc::AsciiDoc::Model::Inline::Highlight.new(
                content: inline.content
              )
            when 'strikethrough'
              Coradoc::AsciiDoc::Model::Inline::Strikethrough.new(
                content: inline.content
              )
            when 'subscript'
              Coradoc::AsciiDoc::Model::Inline::Subscript.new(
                content: inline.content
              )
            when 'superscript'
              Coradoc::AsciiDoc::Model::Inline::Superscript.new(
                content: inline.content
              )
            when 'underline'
              Coradoc::AsciiDoc::Model::Inline::Underline.new(
                text: inline.content
              )
            when 'link'
              Coradoc::AsciiDoc::Model::Inline::Link.new(
                path: inline.target,
                name: inline.content
              )
            when 'xref'
              Coradoc::AsciiDoc::Model::Inline::CrossReference.new(
                href: inline.target
              )
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
              Coradoc::AsciiDoc::Model::TextElement.new(
                content: inline.content
              )
            end
          end

          def transform_image(image)
            Coradoc::AsciiDoc::Model::Image::BlockImage.new(
              src: image.src,
              title: image.alt,
              attributes: build_image_attributes(image)
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
              # Already an AsciiDoc model - use as-is
              content
            when Lutaml::Model::Serializable
              # Lutaml model that's not a recognized type - extract text safely
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
              # For unknown types, convert to string safely
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
