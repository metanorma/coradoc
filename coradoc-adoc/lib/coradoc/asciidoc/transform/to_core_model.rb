# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Transforms AsciiDoc models to CoreModel equivalents
      #
      # This transformer converts the format-specific AsciiDoc model
      # to the canonical CoreModel representation.
      class ToCoreModel
        # Instance method that delegates to class method for convenience
        def transform(model)
          self.class.transform(model)
        end

        class << self
          # Transform an AsciiDoc model to CoreModel
          #
          # First checks the Registry for a registered transformer.
          # If none found, falls back to the case statement implementation.
          #
          # @param model [Coradoc::AsciiDoc::Model::Base] AsciiDoc model to transform
          # @return [Coradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            # Check if there's a registered transformer
            transformer = Registry.lookup(model.class) if model.is_a?(Coradoc::AsciiDoc::Model::Base)

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
              # Generic block - use delimiter directly
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
            when Coradoc::AsciiDoc::Model::Image::BlockImage
              transform_image(model)
            when Coradoc::AsciiDoc::Model::TextElement
              extract_text_content(model)
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end

          # Determine block type from delimiter
          def determine_block_type(delimiter)
            return 'unknown' if delimiter.nil? || delimiter.empty?

            case delimiter.chars.first
            when '-'
              'listing'
            when '='
              'example'
            when '_'
              'quote'
            when '*'
              'sidebar'
            when '.'
              'literal'
            when '+'
              'pass'
            else
              delimiter
            end
          end

          private

          def transform_document(doc)
            title_text = extract_title_text(doc.header&.title)
            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              id: doc.id,
              title: title_text,
              children: transform(doc.sections || doc.contents || [])
            )
          end

          def transform_section(section)
            title_text = extract_title_text(section.title)
            # Transform both contents and nested sections
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
            # Transform paragraph content, preserving inline elements
            children = transform_inline_content(para.content)

            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              id: para.id,
              content: extract_text_content(para.content),
              children: children
            )
          end

          # Transform inline content, preserving inline element structure
          # Returns an array of strings and CoreModel::InlineElement objects
          def transform_inline_content(content)
            return [] if content.nil?

            case content
            when Array
              content.flat_map { |item| transform_inline_content(item) }
            when Coradoc::AsciiDoc::Model::TextElement
              transform_inline_content(content.content)
            when Coradoc::AsciiDoc::Model::Inline::Bold
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'bold',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Italic
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'italic',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Monospace
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'monospace',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Highlight
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'highlight',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Strikethrough
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'strikethrough',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Subscript
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'subscript',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Superscript
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'superscript',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Underline
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'underline',
                content: extract_text_content(content.content)
              )]
            when Coradoc::AsciiDoc::Model::Inline::Link
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'link',
                target: content.path,
                content: content.name || content.path
              )]
            when Coradoc::AsciiDoc::Model::Inline::CrossReference
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'xref',
                target: content.href,
                content: content.args&.first || content.href
              )]
            when Coradoc::AsciiDoc::Model::Inline::Footnote
              # Parse footnote text for inline elements (e.g., stem:[t_90])
              footnote_text = content.text.to_s
              parsed_content = parse_and_transform_inline(footnote_text)

              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'footnote',
                target: content.id,
                content: parsed_content
              )]
            when Coradoc::AsciiDoc::Model::Inline::Stem
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'stem',
                content: content.content.to_s
              )]
            when Coradoc::AsciiDoc::Model::Term
              [Coradoc::CoreModel::InlineElement.new(
                format_type: 'term',
                content: content.term.to_s
              )]
            when String
              content.empty? ? [] : [content]
            else
              # For other types, extract as text
              text = extract_text_content(content)
              text.empty? ? [] : [text]
            end
          end

          def transform_block(block, delimiter_type)
            # Transform block content (lines) - they can contain nested elements
            content_lines = Array(block.lines).map do |line|
              case line
              when Coradoc::AsciiDoc::Model::Base
                # Transform nested AsciiDoc model objects to CoreModel
                transformed = transform(line)
                # If it's a CoreModel type, extract text representation
                if transformed.is_a?(Coradoc::CoreModel::Base)
                  extract_core_model_text(transformed)
                else
                  transformed.to_s
                end
              else
                line.to_s
              end
            end.join("\n")

            # Get language from block.lang or attributes
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

          # Extract text representation from CoreModel objects
          def extract_core_model_text(model)
            case model
            when Coradoc::CoreModel::ListBlock
              model.items.map do |item|
                item.is_a?(Coradoc::CoreModel::ListItem) ? "* #{item.content}" : item.to_s
              end.join("\n")
            when Coradoc::CoreModel::Block
              model.content.to_s
            when Coradoc::CoreModel::Image
              # Image should be rendered as empty text - actual rendering handled by HTML converter
              model.alt || ''
            when Coradoc::CoreModel::InlineElement
              model.content.to_s
            else
              # For unknown types, return empty string to avoid Ruby object dumps
              ''
            end
          end

          # Extract text from a Title object
          def extract_title_text(title)
            return nil if title.nil?
            return title.to_s unless title.is_a?(Coradoc::AsciiDoc::Model::Title)

            content = title.content
            return '' if content.nil?

            # Content can be a string or an array
            if content.is_a?(String)
              content
            elsif content.is_a?(Array)
              content.map { |c| extract_text_content(c) }.join
            else
              extract_text_content(content)
            end
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

          def transform_list(list, marker_type)
            items = Array(list.items).map do |item|
              # Handle both ListItem (content) and ListItemDefinition (contents, terms)
              if item.is_a?(Coradoc::AsciiDoc::Model::List::DefinitionItem)
                # Definition list item
                term_content = item.terms
                def_content = item.contents

                Coradoc::CoreModel::DefinitionItem.new(
                  term: extract_text_content(term_content),
                  definitions: [extract_text_content(def_content)]
                )
              else
                # Regular list item - preserve inline elements
                content_val = item.respond_to?(:content) ? item.content : item.contents
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
              term_type: term.type&.to_s || 'preferred',
              language: term.lang&.to_s || 'en'
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

          def transform_link(link)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'link',
              target: link.path,
              content: link.name
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

          def transform_table_row(row)
            cells = Array(row.columns).map do |cell|
              transform_table_cell(cell)
            end
            Coradoc::CoreModel::TableRow.new(cells: cells)
          end

          def transform_table_cell(cell)
            # Transform cell content, preserving inline elements
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

          def extract_text_content(content)
            case content
            when nil
              ''
            when String
              content
            when Array
              # Join text elements with spaces (paragraph normalization)
              # TextElements with line_break should have a space before the next element
              result = []
              content.each_with_index do |item, idx|
                text = extract_text_content(item)
                result << text if text && !text.empty?

                # Add space between adjacent text elements (unless it's the last one)
                next unless idx < content.length - 1 && text && !text.empty?

                # Add space unless the current item ends with a hard line break
                result << ' ' if item.is_a?(Coradoc::AsciiDoc::Model::TextElement) && item.line_break != '+'
              end
              result.join
            when Coradoc::AsciiDoc::Model::TextElement
              # TextElement.content can be a string or an array of inline elements
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
              # Inline formatting - extract content
              extract_text_content(content.content)
            when Coradoc::AsciiDoc::Model::Inline::Link
              # Link - return the link text or URL
              content.name || content.path || ''
            when Coradoc::AsciiDoc::Model::Inline::CrossReference
              content.href || ''
            when Coradoc::AsciiDoc::Model::Inline::Stem
              # STEM formula - return the content
              content.content.to_s
            when Coradoc::AsciiDoc::Model::Inline::Footnote
              # Footnote - return the content or reference
              if content.respond_to?(:content) && content.content
                extract_text_content(content.content)
              else
                ''
              end
            when Coradoc::AsciiDoc::Model::Inline::AttributeReference
              "{#{content.name}}"
            when Coradoc::AsciiDoc::Model::Term
              content.term.to_s
            when Coradoc::CoreModel::Image
              # CoreModel Image - return alt text or empty
              content.alt || content.src || ''
            when Coradoc::AsciiDoc::Model::Base
              if content.respond_to?(:content)
                extract_text_content(content.content)
              else
                ''
              end
            else
              # Handle unknown types - try to_s for simple types like Parslet::Slice
              # but return empty string for complex objects to avoid Ruby object dumps
              if content.respond_to?(:to_str)
                content.to_s
              elsif content.class.name.start_with?('Parslet::')
                content.to_s
              else
                ''
              end
            end
          end

          # Parse raw text for inline elements and transform to CoreModel
          # Used for footnote content and other places where raw text may contain inline markup
          # @param text [String] Raw text that may contain inline markup
          # @return [Array, String] Array of CoreModel elements or original string if no inline elements
          def parse_and_transform_inline(text)
            return text if text.nil? || text.to_s.strip.empty?

            # Check if text contains any inline markup patterns
            inline_patterns = [
              /stem:\[/,        # STEM formulas: stem:[formula]
              /term:\[/,        # Term references: term:[text]
              /footnote:\[/,    # Footnotes: footnote:[text]
              /\{[a-zA-Z_]+\}/, # Attribute references: {name}
              %r{https?://},    # Links
              /<[^>]+>/         # HTML tags or cross-refs
            ]

            has_inline_markup = inline_patterns.any? { |pattern| text =~ pattern }
            return text unless has_inline_markup

            # Parse the text for inline elements using the Transformer
            begin
              parsed_elements = Coradoc::AsciiDoc::Transformer.parse_inline_content(text)
              # Extract the content from TextElement wrappers
              content_array = parsed_elements.flat_map do |element|
                if element.is_a?(Coradoc::AsciiDoc::Model::TextElement)
                  element.content
                else
                  element
                end
              end

              # Transform the parsed inline elements to CoreModel
              transformed = transform_inline_content(content_array)

              # If we only got back strings with no inline elements, return the original text
              if transformed.all? { |item| item.is_a?(String) }
                transformed.join
              else
                transformed
              end
            rescue StandardError
              # If parsing fails, return the original text
              text
            end
          end
        end
      end
    end
  end
end
