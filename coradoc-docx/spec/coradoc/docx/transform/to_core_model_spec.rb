# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Coradoc::Docx::Transform::ToCoreModel do
  describe '.transform' do
    it 'returns a StructuralElement with element_type document' do
      doc = build_document
      core = transform_to_core(doc)

      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.element_type).to eq('document')
    end

    context 'with headings' do
      it 'converts Heading1 to document title' do
        doc = build_document
        doc.body.paragraphs << build_heading('Title', level: 1)

        core = transform_to_core(doc)

        expect(core.title).to eq('Title')
      end

      it 'does not duplicate H1 as both title and child' do
        doc = build_document
        doc.body.paragraphs << build_heading('Title', level: 1)

        core = transform_to_core(doc)

        # Title is on the document, not as a child section
        sections = core.children.select { |c| c.is_a?(Coradoc::CoreModel::StructuralElement) }
        expect(sections.map(&:title)).not_to include('Title')
      end

      it 'converts Heading2 to section child' do
        doc = build_document
        doc.body.paragraphs << build_heading('Title', level: 1)
        doc.body.paragraphs << build_heading('Section', level: 2)

        core = transform_to_core(doc)

        sections = core.children.select { |c| c.is_a?(Coradoc::CoreModel::StructuralElement) }
        expect(sections.length).to eq(1)
        expect(sections.first.title).to eq('Section')
        expect(sections.first.level).to eq(2)
      end
    end

    context 'with paragraphs' do
      it 'converts plain text to Block paragraph' do
        doc = build_document
        doc.body.paragraphs << build_paragraph('Hello World')

        core = transform_to_core(doc)

        blocks = core.children.select { |c| c.is_a?(Coradoc::CoreModel::Block) }
        expect(blocks.length).to eq(1)
        expect(blocks.first.element_type).to eq('paragraph')
        expect(blocks.first.content).to eq('Hello World')
      end

      it 'converts bold run to InlineElement in children' do
        doc = build_document
        doc.body.paragraphs << build_paragraph(build_run('bold', bold: true))

        core = transform_to_core(doc)

        blocks = core.children.select { |c| c.is_a?(Coradoc::CoreModel::Block) }
        expect(blocks.first.content).to eq('bold')
        inline = blocks.first.children.find { |c| c.is_a?(Coradoc::CoreModel::InlineElement) }
        expect(inline).not_to be_nil
        expect(inline.format_type).to eq('bold')
        expect(inline.content).to eq('bold')
      end

      it 'converts italic run to InlineElement in children' do
        doc = build_document
        doc.body.paragraphs << build_paragraph(build_run('italic', italic: true))

        core = transform_to_core(doc)

        blocks = core.children.select { |c| c.is_a?(Coradoc::CoreModel::Block) }
        expect(blocks.first.content).to eq('italic')
        inline = blocks.first.children.find { |c| c.is_a?(Coradoc::CoreModel::InlineElement) }
        expect(inline).not_to be_nil
        expect(inline.format_type).to eq('italic')
        expect(inline.content).to eq('italic')
      end

      it 'handles mixed formatting in a paragraph' do
        doc = build_document
        doc.body.paragraphs << build_paragraph(
          'Normal ',
          build_run('bold', bold: true),
          ' and ',
          build_run('italic', italic: true)
        )

        core = transform_to_core(doc)

        blocks = core.children.select { |c| c.is_a?(Coradoc::CoreModel::Block) }
        expect(blocks.first.content).to eq('Normal bold and italic')
        inlines = blocks.first.children.select { |c| c.is_a?(Coradoc::CoreModel::InlineElement) }
        expect(inlines.length).to eq(2)
        expect(inlines[0].format_type).to eq('bold')
        expect(inlines[1].format_type).to eq('italic')
      end
    end

    context 'with tables' do
      it 'converts OOXML table to CoreModel::Table' do
        doc = build_document
        doc.body.tables << build_table([
                                         %w[Name Value],
                                         %w[Key1 Val1]
                                       ])

        core = transform_to_core(doc)

        tables = core.children.select { |c| c.is_a?(Coradoc::CoreModel::Table) }
        expect(tables.length).to eq(1)
        expect(tables.first.rows.length).to eq(2)
        expect(tables.first.rows[0].cells.length).to eq(2)
        expect(tables.first.rows[0].cells[0].content).to eq('Name')
      end

      it 'preserves cell content' do
        doc = build_document
        doc.body.tables << build_table([%w[A B]])

        core = transform_to_core(doc)

        table = core.children.find { |c| c.is_a?(Coradoc::CoreModel::Table) }
        expect(table.rows[0].cells.map(&:content)).to eq(%w[A B])
      end
    end

    context 'with lists' do
      it 'groups consecutive list items into a ListBlock' do
        doc = build_document
        doc.body.paragraphs << build_list_paragraph('Item 1', num_id: 1)
        doc.body.paragraphs << build_list_paragraph('Item 2', num_id: 1)
        doc.body.paragraphs << build_list_paragraph('Item 3', num_id: 1)

        core = transform_to_core(doc)

        lists = core.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
        expect(lists.length).to eq(1)
        expect(lists.first.items.length).to eq(3)
      end

      it 'separates lists with different numId' do
        doc = build_document
        doc.body.paragraphs << build_list_paragraph('Item A1', num_id: 1)
        doc.body.paragraphs << build_list_paragraph('Item A2', num_id: 1)
        doc.body.paragraphs << build_paragraph('Normal paragraph')
        doc.body.paragraphs << build_list_paragraph('Item B1', num_id: 2)

        core = transform_to_core(doc)

        lists = core.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
        expect(lists.length).to eq(2)
        expect(lists[0].items.length).to eq(2)
        expect(lists[1].items.length).to eq(1)
      end
    end

    context 'with empty document' do
      it 'returns empty children' do
        doc = build_document

        core = transform_to_core(doc)

        expect(core.children).to eq([])
        expect(core.title).to be_nil
      end
    end
  end
end
