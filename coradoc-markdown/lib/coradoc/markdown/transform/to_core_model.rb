# frozen_string_literal: true

require 'coradoc/core_model'

module Coradoc
  module Markdown
    module Transform
      # Transforms Markdown models to CoreModel equivalents
      #
      # This transformer converts the format-specific Markdown model
      # to the canonical CoreModel representation.
      class ToCoreModel
        class << self
          # Transform a Markdown model to CoreModel
          #
          # @param model [Coradoc::Markdown::Base] Markdown model to transform
          # @return [Coradoc::CoreModel::Base] CoreModel equivalent
          def transform(model)
            case model
            when Coradoc::Markdown::Document
              transform_document(model)
            when Coradoc::Markdown::Heading
              transform_heading(model)
            when Coradoc::Markdown::Paragraph
              transform_paragraph(model)
            when Coradoc::Markdown::CodeBlock
              transform_code_block(model)
            when Coradoc::Markdown::Blockquote
              transform_blockquote(model)
            when Coradoc::Markdown::List
              transform_list(model)
            when Coradoc::Markdown::DefinitionList
              transform_definition_list(model)
            when Coradoc::Markdown::Table
              transform_table(model)
            when Coradoc::Markdown::Image
              transform_image(model)
            when Coradoc::Markdown::Link
              transform_link(model)
            when Coradoc::Markdown::Emphasis
              transform_inline(model, 'italic')
            when Coradoc::Markdown::Strong
              transform_inline(model, 'bold')
            when Coradoc::Markdown::Code
              transform_inline(model, 'monospace')
            when Coradoc::Markdown::Footnote
              transform_footnote(model)
            when Coradoc::Markdown::FootnoteReference
              transform_footnote_reference(model)
            when Coradoc::Markdown::Abbreviation
              transform_abbreviation(model)
            when Coradoc::Markdown::HorizontalRule
              transform_horizontal_rule(model)
            when Coradoc::Markdown::Math
              transform_math(model)
            when Coradoc::Markdown::Extension
              transform_extension(model)
            when Coradoc::Markdown::AttributeList
              transform_attribute_list(model)
            when Coradoc::Markdown::Text
              model.content.to_s
            when Array
              model.map { |item| transform(item) }
            else
              model
            end
          end

          private

          def transform_document(doc)
            children = Array(doc.blocks).map { |block| transform(block) }

            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              id: doc.id,
              title: extract_title(doc),
              children: children
            )
          end

          def transform_heading(heading)
            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'section',
              level: heading.level,
              title: extract_text(heading.text),
              children: []
            )
          end

          def transform_paragraph(para)
            content = extract_text(para.text)

            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: content
            )
          end

          def transform_code_block(block)
            Coradoc::CoreModel::Block.new(
              element_type: 'block',
              delimiter_type: '```',
              content: block.code.to_s,
              language: block.language
            )
          end

          def transform_blockquote(blockquote)
            Coradoc::CoreModel::Block.new(
              element_type: 'block',
              delimiter_type: '>',
              content: blockquote.content.to_s
            )
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              Coradoc::CoreModel::ListItem.new(
                content: extract_text(item.text),
                marker: list.ordered ? '1.' : '*'
              )
            end

            Coradoc::CoreModel::ListBlock.new(
              marker_type: list.ordered ? 'ordered' : 'unordered',
              items: items
            )
          end

          def transform_table(table)
            # Convert Markdown table to CoreModel table
            rows = []

            # Add header row if present
            if table.headers.any?
              rows << Coradoc::CoreModel::TableRow.new(
                cells: table.headers.map do |h|
                  Coradoc::CoreModel::TableCell.new(content: h.to_s, header: true)
                end
              )
            end

            # Add data rows
            table.rows.each do |row|
              cells = if row.is_a?(Array)
                        row.map { |c| Coradoc::CoreModel::TableCell.new(content: c.to_s, header: false) }
                      else
                        [Coradoc::CoreModel::TableCell.new(content: row.to_s, header: false)]
                      end
              rows << Coradoc::CoreModel::TableRow.new(cells: cells)
            end

            Coradoc::CoreModel::Table.new(rows: rows)
          end

          def transform_image(image)
            Coradoc::CoreModel::Image.new(
              src: image.src,
              alt: image.alt.to_s
            )
          end

          def transform_link(link)
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'link',
              target: link.url,
              content: extract_text(link.text)
            )
          end

          def transform_inline(inline, format_type)
            Coradoc::CoreModel::InlineElement.new(
              format_type: format_type,
              content: extract_text(inline.text)
            )
          end

          def transform_horizontal_rule(_rule)
            Coradoc::CoreModel::Block.new(
              element_type: 'block',
              delimiter_type: '---'
            )
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |term|
              definitions = Array(term.definitions).map do |defn|
                defn.content.to_s
              end
              Coradoc::CoreModel::DefinitionItem.new(
                term: term.text.to_s,
                definitions: definitions
              )
            end

            Coradoc::CoreModel::DefinitionList.new(items: items)
          end

          def transform_footnote(fn)
            Coradoc::CoreModel::Footnote.new(
              id: fn.id.to_s,
              content: fn.content.to_s,
              backlink: fn.backlink.nil? || fn.backlink
            )
          end

          def transform_footnote_reference(ref)
            Coradoc::CoreModel::FootnoteReference.new(id: ref.id.to_s)
          end

          def transform_abbreviation(abbr)
            Coradoc::CoreModel::Abbreviation.new(
              term: abbr.term.to_s,
              definition: abbr.definition.to_s
            )
          end

          def transform_math(math)
            if math.inline?
              Coradoc::CoreModel::InlineElement.new(
                format_type: 'stem',
                content: math.content.to_s
              )
            else
              Coradoc::CoreModel::Block.new(
                element_type: 'block',
                delimiter_type: '++++',
                content: math.content.to_s,
                language: 'latexmath'
              )
            end
          end

          def transform_extension(ext)
            case ext.name.to_sym
            when :toc
              Coradoc::CoreModel::Toc.new
            when :comment
              Coradoc::CoreModel::Block.new(
                element_type: 'comment',
                content: ext.content.to_s
              )
            when :nomarkdown
              Coradoc::CoreModel::Block.new(
                element_type: 'block',
                delimiter_type: '++++',
                content: ext.content.to_s
              )
            else
              # Unknown extensions: preserve content as a generic block
              Coradoc::CoreModel::Block.new(
                element_type: 'paragraph',
                content: ext.content.to_s
              )
            end
          end

          def transform_attribute_list(attr_list)
            attrs = []
            attrs << Coradoc::CoreModel::ElementAttribute.new(name: 'id', value: attr_list.id.to_s) if attr_list.id
            attr_list.classes.each do |cls|
              attrs << Coradoc::CoreModel::ElementAttribute.new(name: 'class', value: cls.to_s)
            end
            attr_list.attributes.each do |k, v|
              attrs << Coradoc::CoreModel::ElementAttribute.new(name: k.to_s, value: v.to_s)
            end

            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'attribute_list',
              children: attrs
            )
          end

          def extract_text(text)
            return '' if text.nil?
            return text.to_s unless text.is_a?(Coradoc::Markdown::Text)

            text.content.to_s
          end

          def extract_title(doc)
            # Try to get title from first heading
            first_block = Array(doc.blocks).first
            return extract_text(first_block.text) if first_block.is_a?(Coradoc::Markdown::Heading)

            nil
          end
        end
      end
    end
  end
end
