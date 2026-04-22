# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      # Transforms CoreModel models to Markdown equivalents
      #
      # This transformer converts the canonical CoreModel representation
      # to format-specific Markdown model.
      class FromCoreModel
        class << self
          # Transform a CoreModel to Markdown model
          #
          # @param model [Coradoc::CoreModel::Base] CoreModel to transform
          # @return [Coradoc::Markdown::Base] Markdown model equivalent
          def transform(model)
            case model
            when Coradoc::CoreModel::StructuralElement
              transform_structural_element(model)
            when Coradoc::CoreModel::Block
              transform_block(model)
            when Coradoc::CoreModel::ListBlock
              transform_list(model)
            when Coradoc::CoreModel::DefinitionList
              transform_definition_list(model)
            when Coradoc::CoreModel::Table
              transform_table(model)
            when Coradoc::CoreModel::Image
              transform_image(model)
            when Coradoc::CoreModel::InlineElement
              transform_inline(model)
            when Coradoc::CoreModel::Footnote
              transform_footnote(model)
            when Coradoc::CoreModel::FootnoteReference
              transform_footnote_reference(model)
            when Coradoc::CoreModel::Abbreviation
              transform_abbreviation(model)
            when Coradoc::CoreModel::Toc
              Coradoc::Markdown::Extension.toc
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
              transform_document(element)
            when 'section'
              transform_section(element)
            else
              transform_generic_element(element)
            end
          end

          def transform_document(doc)
            blocks = Array(doc.children).map { |child| transform(child) }

            Coradoc::Markdown::Document.new(
              id: doc.id,
              blocks: blocks
            )
          end

          def transform_section(section)
            Coradoc::Markdown::Heading.new(
              level: section.level || 1,
              text: section.title.to_s
            )
          end

          def transform_generic_element(element)
            blocks = Array(element.children).map { |child| transform(child) }

            Coradoc::Markdown::Document.new(
              id: element.id,
              blocks: blocks
            )
          end

          def transform_block(block)
            case block.element_type
            when 'paragraph'
              transform_paragraph(block)
            when 'comment'
              Coradoc::Markdown::Extension.comment(block.content.to_s)
            else
              transform_delimited_block(block)
            end
          end

          def transform_paragraph(block)
            content = block.renderable_content
            if content.is_a?(Array) && content.any? { |c| !c.is_a?(String) }
              # Mixed content with inline elements
              children = content.map { |c| transform_inline_content(c) }
              Coradoc::Markdown::Paragraph.new(text: block.content.to_s, children: children)
            else
              Coradoc::Markdown::Paragraph.new(text: block.content.to_s)
            end
          end

          def transform_inline_content(element)
            case element
            when Coradoc::CoreModel::InlineElement
              transform_inline(element)
            when String
              element
            else
              element.to_s
            end
          end

          def transform_delimited_block(block)
            delimiter = block.delimiter_type

            case delimiter
            when '```', '~'
              transform_code_block(block)
            when '>'
              transform_blockquote(block)
            when '---', '***', '___'
              transform_horizontal_rule(block)
            when '++++'
              Coradoc::Markdown::Extension.nomarkdown(block.content.to_s)
            else
              transform_paragraph(block)
            end
          end

          def transform_code_block(block)
            Coradoc::Markdown::CodeBlock.new(
              code: block.content.to_s,
              language: block.language
            )
          end

          def transform_blockquote(block)
            content = block.content.to_s

            Coradoc::Markdown::Blockquote.new(content: content)
          end

          def transform_horizontal_rule(_block)
            Coradoc::Markdown::HorizontalRule.new
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              content = item.renderable_content
              if content.is_a?(Array) && content.any? { |c| !c.is_a?(String) }
                children = content.map { |c| transform_inline_content(c) }
                Coradoc::Markdown::ListItem.new(text: item.content.to_s, children: children)
              else
                Coradoc::Markdown::ListItem.new(text: item.content.to_s)
              end
            end

            Coradoc::Markdown::List.new(
              ordered: list.marker_type == 'ordered',
              items: items
            )
          end

          def transform_table(table)
            # Extract headers from first row if cells are marked as headers
            headers = []
            rows = []

            table_rows = Array(table.rows)
            if table_rows.any?
              first_row = table_rows.first
              first_row_cells = Array(first_row&.cells)

              # Check if first row has header cells
              if first_row_cells.any?(&:header)
                headers = first_row_cells.map { |c| c.content.to_s }
                table_rows = table_rows[1..] || []
              end

              # Convert remaining rows to pipe-separated strings
              rows = table_rows.map do |row|
                Array(row.cells).map { |c| c.content.to_s }.join(' | ')
              end
            end

            Coradoc::Markdown::Table.new(
              headers: headers,
              rows: rows
            )
          end

          def transform_image(image)
            Coradoc::Markdown::Image.new(
              src: image.src,
              alt: image.alt.to_s
            )
          end

          def transform_inline(element)
            case element.format_type
            when 'bold'
              Coradoc::Markdown::Strong.new(text: element.content.to_s)
            when 'italic'
              Coradoc::Markdown::Emphasis.new(text: element.content.to_s)
            when 'monospace'
              Coradoc::Markdown::Code.new(text: element.content.to_s)
            when 'link'
              Coradoc::Markdown::Link.new(
                text: element.content.to_s,
                url: element.target.to_s
              )
            when 'footnote'
              Coradoc::Markdown::FootnoteReference.new(id: element.target.to_s)
            when 'stem'
              Coradoc::Markdown::Math.inline(element.content.to_s)
            else
              element.content.to_s
            end
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |item|
              definitions = Array(item.definitions).map do |defn|
                Coradoc::Markdown::DefinitionItem.new(content: defn.to_s)
              end
              Coradoc::Markdown::DefinitionTerm.new(
                text: item.term.to_s,
                definitions: definitions
              )
            end

            Coradoc::Markdown::DefinitionList.new(items: items)
          end

          def transform_footnote(fn)
            Coradoc::Markdown::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Coradoc::Markdown::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Coradoc::Markdown::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end
        end
      end
    end
  end
end
