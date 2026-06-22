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
            when Coradoc::CoreModel::AnnotationBlock
              # Must be checked before Block since AnnotationBlock < Block
              transform_annotation_block(model)
            when Coradoc::CoreModel::CommentBlock
              # Must be checked before Block since CommentBlock < Block
              Coradoc::Markdown::Comment.new(text: model.content.to_s)
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
            when Coradoc::CoreModel::Term
              Coradoc::Markdown::Strong.new(text: model.text.to_s)
            when Coradoc::CoreModel::Bibliography
              transform_bibliography(model)
            when Coradoc::CoreModel::BibliographyEntry
              transform_bibliography_entry(model)
            when Coradoc::CoreModel::TocEntry
              Coradoc::Markdown::Text.new(content: model.title.to_s)
            when Coradoc::CoreModel::CommentLine
              Coradoc::Markdown::Comment.new(text: model.text.to_s)
            when Coradoc::CoreModel::TextContent
              model.text.to_s
            when Array
              model.flat_map { |item| flatten_result(transform(item)) }
            else
              model
            end
          end

          private

          def transform_structural_element(element)
            case element
            when CoreModel::DocumentElement
              transform_document(element)
            when CoreModel::SectionElement
              transform_section(element)
            else
              transform_generic_element(element)
            end
          end

          def transform_document(doc)
            blocks, frontmatter = extract_frontmatter(Array(doc.children))
            blocks = blocks.flat_map { |child| flatten_result(transform(child)) }

            Coradoc::Markdown::Document.new(
              id: doc.id,
              blocks: blocks,
              frontmatter: frontmatter
            )
          end

          # If the first CoreModel child is a FrontmatterBlock, serialize
          # it to YAML text via Codec (single source of truth) and pop
          # it from the children list. Returns [remaining_children,
          # frontmatter_text].
          def extract_frontmatter(children)
            first = children.first
            return [children, nil] unless first.is_a?(CoreModel::FrontmatterBlock)

            yaml = CoreModel::FrontmatterBlock::Codec.to_yaml(first)
            [children.drop(1), yaml.nil? || yaml.empty? ? nil : yaml]
          end

          def transform_section(section)
            heading = Coradoc::Markdown::Heading.new(
              level: section.level || 1,
              text: section.title.to_s
            )
            child_blocks = Array(section.children).map { |child| transform(child) }
            [heading, *child_blocks]
          end

          def transform_generic_element(element)
            blocks = Array(element.children).flat_map { |child| flatten_result(transform(child)) }

            Coradoc::Markdown::Document.new(
              id: element.id,
              blocks: blocks
            )
          end

          def transform_block(block)
            semantic = block.resolve_semantic_type
            case semantic
            when :paragraph
              transform_paragraph(block)
            when :comment
              Coradoc::Markdown::Comment.new(text: block.content.to_s)
            else
              transform_delimited_block(block)
            end
          end

          def transform_paragraph(block)
            content = block.renderable_content
            has_nested_blocks = content.is_a?(Array) && content.any? do |c|
              c.is_a?(CoreModel::Block) || c.is_a?(CoreModel::StructuralElement)
            end
            if has_nested_blocks
              content.filter_map do |c|
                next c.text if c.is_a?(CoreModel::TextContent)
                next nil if c.is_a?(String) && c.strip.empty?

                transform(c)
              end.flat_map { |c| flatten_result(c) }
            elsif content.is_a?(Array) && content.any? { |c| !c.is_a?(CoreModel::TextContent) }
              children = content.map { |c| transform_inline_content(c) }
              Coradoc::Markdown::Paragraph.new(text: block.flat_text, children: children)
            else
              Coradoc::Markdown::Paragraph.new(text: block.flat_text)
            end
          end

          def transform_inline_content(element)
            case element
            when Coradoc::CoreModel::InlineElement
              transform_inline(element)
            when CoreModel::TextContent
              element.text
            when CoreModel::Base
              transform(element)
            when String
              element
            when Array
              element.map { |e| transform_inline_content(e) }
            else
              element.to_s
            end
          end

          def transform_delimited_block(block)
            semantic = resolve_markdown_semantic(block)

            case semantic
            when :source_code, :listing
              transform_code_block(block)
            when :quote
              transform_blockquote(block)
            when :verse
              transform_verse_block(block)
            when :horizontal_rule
              transform_horizontal_rule(block)
            when :pass
              transform_pass_block(block)
            when :literal
              transform_literal_block(block)
            when :example
              transform_example_block(block)
            when :sidebar
              transform_sidebar_block(block)
            when :open
              transform_open_block(block)
            when :reviewer
              transform_admonition_block(block, default_type: 'reviewer')
            else
              transform_paragraph(block)
            end
          end

          def transform_container_block(block)
            rc = block.renderable_content
            if rc.is_a?(Array) && rc.any? { |c| c.is_a?(CoreModel::Block) || c.is_a?(CoreModel::ListBlock) }
              rc.filter_map do |c|
                next c.text if c.is_a?(CoreModel::TextContent)
                next nil if c.is_a?(String) && c.strip.empty?

                transform(c)
              end.flat_map { |c| flatten_result(c) }
            else
              Coradoc::Markdown::Blockquote.new(content: block.flat_text)
            end
          end

          def transform_verse_block(block)
            Coradoc::Markdown::Verse.new(
              content: block.flat_text,
              attribution: block.respond_to?(:attribution) ? block.attribution : nil
            )
          end

          def transform_pass_block(block)
            return Coradoc::Markdown::Math.block(block.content.to_s) if block.language == 'latexmath'

            Coradoc::Markdown::Pass.new(content: block.content.to_s)
          end

          def transform_literal_block(block)
            Coradoc::Markdown::Literal.new(content: block.content.to_s)
          end

          def transform_example_block(block)
            Coradoc::Markdown::ExampleBlock.new(
              content: block.flat_text,
              caption: block.title.to_s
            )
          end

          def transform_sidebar_block(block)
            Coradoc::Markdown::Sidebar.new(
              content: block.flat_text,
              title: block.title.to_s
            )
          end

          def transform_open_block(block)
            children = Array(block.children).map { |c| transform(c) }.flat_map { |c| flatten_result(c) }
            children = paragraphs_from_content(block.content) if children.empty?
            Coradoc::Markdown::OpenBlock.new(
              children: children,
              id: block.id
            )
          end

          def paragraphs_from_content(content)
            content.to_s.split(/\n\s*\n/).map do |chunk|
              Coradoc::Markdown::Paragraph.new(text: chunk.strip)
            end
          end

          def transform_admonition_block(block, default_type: 'note')
            children = transform_inline_array(block.renderable_content)
            Coradoc::Markdown::Admonition.new(
              admonition_type: block.respond_to?(:annotation_type) ? (block.annotation_type || default_type) : default_type,
              content: block.flat_text,
              title: block.respond_to?(:annotation_label) ? block.annotation_label : nil,
              children: children
            )
          end

          def resolve_markdown_semantic(block)
            # Polymorphic dispatch: typed classes override semantic_type
            semantic = block.resolve_semantic_type
            return semantic if semantic

            # Backward compat: derive from delimiter_type
            markdown_delimiter_to_semantic(block.delimiter_type)
          end

          def markdown_delimiter_to_semantic(delimiter)
            case delimiter
            when '```', '~' then :source_code
            when '>' then :quote
            when '---', '***', '___' then :horizontal_rule
            when '++++' then :pass
            end
          end

          def transform_code_block(block)
            code = CoreModel::CalloutText.strip_markers(block.content.to_s, block.callouts)
            code_block = Coradoc::Markdown::CodeBlock.new(
              code: code,
              language: block.language
            )
            return code_block if block.callouts.nil? || block.callouts.empty?

            [code_block, transform_callout_list(block.callouts)]
          end

          def transform_callout_list(callouts)
            items = CoreModel::CalloutText.ordered(callouts).map do |callout|
              Coradoc::Markdown::ListItem.new(text: callout.content.to_s)
            end
            Coradoc::Markdown::List.new(ordered: true, items: items)
          end

          def transform_blockquote(block)
            content = block.flat_text

            Coradoc::Markdown::Blockquote.new(content: content)
          end

          def transform_horizontal_rule(_block)
            Coradoc::Markdown::HorizontalRule.new(style: '---')
          end

          def transform_list(list)
            items = Array(list.items).map do |item|
              content = item.renderable_content
              has_structured = content.is_a?(Array) && content.any? { |c| !c.is_a?(CoreModel::TextContent) }
              md_item = if has_structured
                          children = content.map { |c| transform_inline_content(c) }
                          Coradoc::Markdown::ListItem.new(text: item.flat_text, children: children)
                        else
                          Coradoc::Markdown::ListItem.new(text: item.flat_text)
                        end
              md_item.sublist = transform_list(item.nested_list) if item.nested_list
              md_item
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

              # Check if first row is marked as header, or if any of its cells are header cells
              if first_row&.header || first_row_cells.any?(&:header)
                headers = first_row_cells.map(&:flat_text)
                table_rows = table_rows[1..] || []
              end

              # Convert remaining rows to pipe-separated strings
              rows = table_rows.map do |row|
                Array(row.cells).map(&:flat_text).join(' | ')
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
            case element.resolve_format_type
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
            when 'highlight'
              Coradoc::Markdown::Highlight.new(text: element.content.to_s)
            when 'strikethrough'
              Coradoc::Markdown::Strikethrough.new(text: element.content.to_s)
            when 'subscript'
              Coradoc::Markdown::Subscript.new(text: element.content.to_s)
            when 'superscript'
              Coradoc::Markdown::Superscript.new(text: element.content.to_s)
            when 'underline'
              Coradoc::Markdown::Underline.new(text: element.content.to_s)
            when 'xref'
              Coradoc::Markdown::CrossReference.new(
                text: element.content.to_s,
                target: element.target.to_s
              )
            else
              element.content.to_s
            end
          end

          def transform_definition_list(dl)
            items = Array(dl.items).map do |item|
              definitions = Array(item.definitions).map do |defn|
                Coradoc::Markdown::DefinitionItem.new(content: defn.to_s)
              end
              nested = item.nested ? transform_definition_list(item.nested) : nil
              Coradoc::Markdown::DefinitionTerm.new(
                text: item.term.to_s,
                definitions: definitions,
                nested: nested
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

          def transform_annotation_block(annotation)
            transform_admonition_block(annotation, default_type: 'note')
          end

          def transform_bibliography(bib)
            entries = Array(bib.entries).map { |e| transform(e) }
            blocks = []
            blocks << Coradoc::Markdown::Heading.new(level: 2, text: bib.title.to_s) if bib.title
            blocks.concat(entries)
            Coradoc::Markdown::Document.new(id: bib.id, blocks: blocks)
          end

          def transform_bibliography_entry(entry)
            text = entry.display_text.to_s
            text = convert_asciidoc_markers_to_markdown(text)
            Coradoc::Markdown::Paragraph.new(text: text)
          end

          def convert_asciidoc_markers_to_markdown(text)
            return '' if text.nil?

            result = text.dup

            # footnote:[text] -> ^[text]
            result.gsub!(/footnote:\[(.*?)\]/, '^[\1]')

            # [smallcap]#text# -> text
            result.gsub!(/\[smallcap\]#(.*?)#/, '\1')

            # *text* -> **text**
            # Use negative lookbehind and lookahead to avoid replacing **text** to ****text****
            result.gsub!(/(?<!\*)\*(.*?)\*(?!\*)/, '**\1**')

            # _text_ -> *text*
            # Use negative lookbehind and lookahead to avoid replacing __text__ to **text**
            result.gsub!(/(?<!_)_(.*?)_(?!_)/, '*\1*')

            result
          end

          def flatten_result(result)
            case result
            when Array
              result.flat_map { |r| flatten_result(r) }
            else
              [result]
            end
          end
        end
      end
    end
  end
end
