# frozen_string_literal: true

require 'uniword'

module Coradoc
  module Docx
    module Transform
      # Transforms CoreModel to OOXML document via Uniword Builder.
      #
      # Follows the hub-and-spoke architecture: CoreModel elements are
      # dispatched to handler methods that produce Uniword OOXML objects.
      # The resulting DocumentRoot is serialized to .docx format.
      #
      # @example Convert CoreModel to DOCX file
      #   Coradoc::Docx::Transform::FromCoreModel.transform_to_file(core, "output.docx")
      #
      # @example Get Uniword DocumentRoot
      #   doc = Coradoc::Docx::Transform::FromCoreModel.transform(core)
      #   doc.save("output.docx")
      class FromCoreModel
        class << self
          # Transform a CoreModel document to a Uniword DocumentRoot
          #
          # @param core [Coradoc::CoreModel::Base] CoreModel document
          # @return [Uniword::Wordprocessingml::DocumentRoot] OOXML document
          def transform(core)
            new.transform(core)
          end

          # Transform a CoreModel document and save to .docx file
          #
          # @param core [Coradoc::CoreModel::Base] CoreModel document
          # @param path [String] output file path
          # @return [void]
          def transform_to_file(core, path)
            doc = transform(core)
            doc.save(path)
          end
        end

        def transform(core)
          case core
          when Coradoc::CoreModel::StructuralElement
            transform_structural_element(core)
          when Coradoc::CoreModel::AnnotationBlock
            transform_annotation_block(core)
          when Coradoc::CoreModel::Block
            transform_block(core)
          when Coradoc::CoreModel::ListBlock
            transform_list(core)
          when Coradoc::CoreModel::Table
            transform_table(core)
          when Coradoc::CoreModel::Image
            transform_image(core)
          when Coradoc::CoreModel::InlineElement
            transform_inline(core)
          when Coradoc::CoreModel::FootnoteReference
            build_ooxml_footnote_reference(core)
          when Coradoc::CoreModel::Footnote
            build_ooxml_footnote(core)
          when Coradoc::CoreModel::DefinitionList
            build_ooxml_definition_list(core)
          when Coradoc::CoreModel::Toc
            build_ooxml_toc(core)
          when Coradoc::CoreModel::Term
            build_ooxml_term(core)
          when Coradoc::CoreModel::Abbreviation
            build_ooxml_abbreviation(core)
          when Coradoc::CoreModel::Bibliography
            build_ooxml_bibliography(core)
          when Coradoc::CoreModel::BibliographyEntry
            build_ooxml_bibliography_entry(core)
          when Coradoc::CoreModel::TocEntry
            build_ooxml_toc_entry(core)
          when Array
            transform_array(core)
          else
            core
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
            transform_section(element)
          end
        end

        def transform_document(element)
          doc = Uniword::Builder::DocumentBuilder.new
          doc.title(element.title) if element.title

          transform_children(element.children, doc)

          doc.build
        end

        def transform_section(element)
          paragraphs = []

          paragraphs << build_heading(element.title, level: element.level || 1) if element.title

          element.children&.each do |child|
            case child
            when Coradoc::CoreModel::StructuralElement
              paragraphs << transform_section(child)
            when Coradoc::CoreModel::Block
              paragraphs << build_ooxml_paragraph(child)
            when Coradoc::CoreModel::ListBlock
              paragraphs.concat(build_ooxml_list(child))
            when Coradoc::CoreModel::Table
              paragraphs << build_ooxml_table(child)
            when Coradoc::CoreModel::Image
              paragraphs << build_ooxml_image(child)
            end
          end

          paragraphs
        end

        def transform_block(block)
          case block.element_type
          when 'page_break'
            build_page_break
          when 'paragraph', nil
            build_ooxml_paragraph(block)
          when 'comment'
            nil
          else
            build_ooxml_paragraph(block)
          end
        end

        def transform_annotation_block(annotation)
          para = Uniword::Wordprocessingml::Paragraph.new
          type_run = Uniword::Wordprocessingml::Run.new
          type_run.text = Uniword::Wordprocessingml::Text.new(
            content: "#{annotation.annotation_type}: "
          )
          type_run.properties = Uniword::Wordprocessingml::RunProperties.new
          type_run.properties.bold = Uniword::Properties::Bold.new

          content = annotation.renderable_content
          text = content.is_a?(Array) ? content.map(&:to_s).join : content.to_s
          text_run = Uniword::Wordprocessingml::Run.new
          text_run.text = Uniword::Wordprocessingml::Text.new(content: text)

          para.runs << type_run
          para.runs << text_run
          para
        end

        def transform_list(list_block)
          build_ooxml_list(list_block)
        end

        def transform_table(table)
          build_ooxml_table(table)
        end

        def transform_image(image)
          build_ooxml_image(image)
        end

        def transform_inline(inline)
          build_ooxml_run(inline)
        end

        def transform_array(elements)
          elements.map { |e| transform(e) }
        end

        # Helper to transform children into builder calls
        def transform_children(children, builder)
          return unless children

          children.each do |child|
            case child
            when Coradoc::CoreModel::StructuralElement
              add_section_to_builder(child, builder)
            when Coradoc::CoreModel::Block
              add_block_to_builder(child, builder)
            when Coradoc::CoreModel::ListBlock
              add_list_to_builder(child, builder)
            when Coradoc::CoreModel::Table
              add_table_to_builder(child, builder)
            when Coradoc::CoreModel::Image
              add_image_to_builder(child, builder)
            end
          end
        end

        def add_section_to_builder(element, builder)
          level = element.level || 1
          builder.heading(element.title, level: level) if element.title

          transform_children(element.children, builder)
        end

        def add_block_to_builder(block, builder)
          case block.element_type
          when 'page_break'
            builder.page_break
          else
            add_paragraph_to_builder(block, builder)
          end
        end

        def add_paragraph_to_builder(block, builder)
          content = block.renderable_content

          if content.is_a?(Array) && content.any? { |c| !c.is_a?(String) }
            builder.paragraph do |p|
              content.each do |child|
                case child
                when String
                  p << child
                when Coradoc::CoreModel::InlineElement
                  p << build_inline_text(child)
                end
              end
            end
          else
            text = content.is_a?(Array) ? content.join : content.to_s
            builder.paragraph(text)
          end
        end

        def add_list_to_builder(list_block, builder)
          method = list_block.marker_type == 'numbered' ? :numbered_list : :bullet_list

          builder.send(method) do |list|
            list_block.items.each do |item|
              content = item.renderable_content
              text = if content.is_a?(Array)
                       content.map { |c| c.is_a?(String) ? c : c.content.to_s }.join
                     else
                       content.to_s
                     end
              list.item(text)
            end
          end
        end

        def add_table_to_builder(table, builder)
          builder.table do |t|
            table.rows.each do |row|
              t.row do |r|
                row.cells.each do |cell|
                  r.cell(text: cell.content.to_s)
                end
              end
            end
          end
        end

        def add_image_to_builder(image, builder)
          if image.src && File.exist?(image.src)
            builder.image(image.src, alt_text: image.alt || '')
          else
            builder.paragraph("[Image: #{image.alt || image.src}]")
          end
        end

        # Build OOXML objects directly (low-level)

        def build_heading(text, level:)
          para = Uniword::Wordprocessingml::Paragraph.new
          para.properties = Uniword::Wordprocessingml::ParagraphProperties.new
          para.properties.style = Uniword::Properties::StyleReference.new(
            value: "Heading#{level}"
          )
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: text)
          para.runs << run
          para
        end

        def build_ooxml_paragraph(block)
          para = Uniword::Wordprocessingml::Paragraph.new

          content = block.renderable_content
          if content.is_a?(Array)
            content.each do |child|
              case child
              when String
                run = Uniword::Wordprocessingml::Run.new
                run.text = Uniword::Wordprocessingml::Text.new(content: child)
                para.runs << run
              when Coradoc::CoreModel::InlineElement
                para.runs << build_ooxml_run(child)
              end
            end
          else
            run = Uniword::Wordprocessingml::Run.new
            run.text = Uniword::Wordprocessingml::Text.new(content: content.to_s)
            para.runs << run
          end

          para.id = block.id if block.id
          para
        end

        def build_ooxml_run(inline)
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: inline.content.to_s)

          props = Uniword::Wordprocessingml::RunProperties.new

          case inline.format_type
          when 'bold'
            props.bold = Uniword::Properties::Bold.new
          when 'italic'
            props.italic = Uniword::Properties::Italic.new
          when 'underline'
            props.underline = Uniword::Properties::Underline.new
          when 'strikethrough'
            props.strike = Uniword::Properties::Strike.new
          when 'subscript'
            va = Uniword::Wordprocessingml::VerticalAlign.new
            va.value = 'subscript'
            props.vertical_align = va
          when 'superscript'
            va = Uniword::Wordprocessingml::VerticalAlign.new
            va.value = 'superscript'
            props.vertical_align = va
          when 'monospace'
            # Monospace via font
            props.font = 'Courier New' if props.respond_to?(:font=)
          when 'link'
            # Links need to be at the paragraph level (w:hyperlink)
            # Return the run; caller should wrap in Hyperlink
            return run
          when 'highlight'
            hl = Uniword::Properties::Highlight.new
            hl.value = 'yellow'
            props.highlight = hl
          when 'xref'
            return run
          when 'stem'
            return run
          end

          run.properties = props unless plain_properties?(props)
          run
        end

        def build_ooxml_list(list_block)
          items = list_block.items || []
          items.map do |item|
            para = Uniword::Wordprocessingml::Paragraph.new
            para.properties = Uniword::Wordprocessingml::ParagraphProperties.new
            para.properties.num_id = 1
            para.properties.ilvl = (list_block.marker_level || 1) - 1

            content = item.renderable_content
            text = if content.is_a?(Array)
                     content.map { |c| c.is_a?(String) ? c : c.content.to_s }.join
                   else
                     content.to_s
                   end
            run = Uniword::Wordprocessingml::Run.new
            run.text = Uniword::Wordprocessingml::Text.new(content: text)
            para.runs << run
            para
          end
        end

        def build_ooxml_table(table)
          tbl = Uniword::Wordprocessingml::Table.new

          table.rows.each do |row|
            tr = Uniword::Wordprocessingml::TableRow.new
            row.cells.each do |cell|
              tc = Uniword::Wordprocessingml::TableCell.new

              para = Uniword::Wordprocessingml::Paragraph.new
              run = Uniword::Wordprocessingml::Run.new
              run.text = Uniword::Wordprocessingml::Text.new(content: cell.content.to_s)
              para.runs << run
              tc.paragraphs << para

              tc.column_span = cell.colspan if cell.colspan && cell.colspan > 1
              tc.row_span = cell.rowspan if cell.rowspan && cell.rowspan > 1

              tr.cells << tc
            end
            tbl.rows << tr
          end

          tbl
        end

        def build_ooxml_image(image)
          if image.src && File.exist?(image.src)
            run = Uniword::Builder::ImageBuilder.create_run(
              nil, image.src, alt_text: image.alt
            )
            para = Uniword::Wordprocessingml::Paragraph.new
          else
            para = Uniword::Wordprocessingml::Paragraph.new
            run = Uniword::Wordprocessingml::Run.new
            run.text = Uniword::Wordprocessingml::Text.new(
              content: "[Image: #{image.alt || image.src}]"
            )
          end
          para.runs << run
          para
        end

        def build_page_break
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.break = Uniword::Wordprocessingml::Break.new
          run.break.type = 'page'
          para.runs << run
          para
        end

        def build_inline_text(inline)
          text = inline.content.to_s

          formatting = {}
          case inline.format_type
          when 'bold'    then formatting[:bold] = true
          when 'italic'  then formatting[:italic] = true
          when 'underline' then formatting[:underline] = true
          when 'strikethrough' then formatting[:strike] = true
          when 'highlight' then formatting[:highlight] = true
          end

          if formatting.any?
            Uniword::Builder.text(text, **formatting)
          else
            text
          end
        end

        def plain_properties?(props)
          props.bold.nil? &&
            props.italic.nil? &&
            props.underline.nil? &&
            props.strike.nil? &&
            props.vertical_align.nil? &&
            props.highlight.nil?
        end

        # Build OOXML footnote reference (w:footnoteReference)
        def build_ooxml_footnote_reference(footnote_ref)
          ref = Uniword::Wordprocessingml::FootnoteReference.new
          ref.id = footnote_ref.id.to_s

          run = Uniword::Wordprocessingml::Run.new
          run.footnote_reference = ref
          run
        end

        # Build OOXML footnote content as a paragraph placeholder
        def build_ooxml_footnote(footnote)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: footnote.content.to_s)
          para.runs << run
          para
        end

        # Build OOXML definition list as a two-column table
        def build_ooxml_definition_list(dl)
          tbl = Uniword::Wordprocessingml::Table.new

          Array(dl.items).each do |item|
            row = Uniword::Wordprocessingml::TableRow.new

            term_cell = Uniword::Wordprocessingml::TableCell.new
            term_para = Uniword::Wordprocessingml::Paragraph.new
            term_run = Uniword::Wordprocessingml::Run.new
            term_run.text = Uniword::Wordprocessingml::Text.new(content: item.term.to_s)
            term_props = Uniword::Wordprocessingml::RunProperties.new
            term_props.bold = Uniword::Properties::Bold.new
            term_run.properties = term_props
            term_para.runs << term_run
            term_cell.paragraphs << term_para

            def_cell = Uniword::Wordprocessingml::TableCell.new
            def_text = Array(item.definitions).map(&:to_s).join('; ')
            def_para = Uniword::Wordprocessingml::Paragraph.new
            def_run = Uniword::Wordprocessingml::Run.new
            def_run.text = Uniword::Wordprocessingml::Text.new(content: def_text)
            def_para.runs << def_run
            def_cell.paragraphs << def_para

            row.cells << term_cell
            row.cells << def_cell
            tbl.rows << row
          end

          tbl
        end

        # Build OOXML TOC as a text placeholder
        def build_ooxml_toc(_toc)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: '[Table of Contents]')
          para.runs << run
          para
        end

        # Build OOXML term as a bold paragraph
        def build_ooxml_term(term)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: term.text.to_s)
          run_props = Uniword::Wordprocessingml::RunProperties.new
          run_props.bold = Uniword::Properties::Bold.new
          run.properties = run_props
          para.runs << run
          para
        end

        def build_ooxml_abbreviation(abbr)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          text = abbr.term.to_s
          text += " (#{abbr.definition})" if abbr.definition
          run.text = Uniword::Wordprocessingml::Text.new(content: text)
          para.runs << run
          para
        end

        def build_ooxml_bibliography(bib)
          entries = Array(bib.entries).map { |e| build_ooxml_bibliography_entry(e) }

          result = []
          result << build_heading(bib.title, level: bib.level || 2) if bib.title
          result.concat(entries)
          result
        end

        def build_ooxml_bibliography_entry(entry)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: entry.display_text)
          para.runs << run
          para
        end

        def build_ooxml_toc_entry(entry)
          para = Uniword::Wordprocessingml::Paragraph.new
          run = Uniword::Wordprocessingml::Run.new
          run.text = Uniword::Wordprocessingml::Text.new(content: entry.title.to_s)
          para.runs << run
          para
        end
      end
    end
  end
end
