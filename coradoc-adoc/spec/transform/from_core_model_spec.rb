# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::FromCoreModel do
  let(:transformer) { described_class.new }

  describe '#transform' do
    context 'when transforming a document' do
      it 'transforms a CoreModel document to AsciiDoc' do
        doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          title: 'Test Document',
          children: []
        )

        result = transformer.transform(doc)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
        expect(result.header.title.content).to eq('Test Document')
      end
    end

    context 'when transforming a section' do
      it 'transforms a CoreModel section to AsciiDoc' do
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          id: 'intro',
          level: 2,
          title: 'Introduction',
          children: []
        )

        result = transformer.transform(section)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Section)
        expect(result.id).to eq('intro')
        expect(result.level).to eq(2)
        expect(result.title.content).to eq('Introduction')
      end
    end

    context 'when transforming a block' do
      it 'transforms a CoreModel block to AsciiDoc' do
        block = Coradoc::CoreModel::Block.new(
          id: 'example-1',
          delimiter_type: '====',
          content: "Line 1\nLine 2"
        )

        result = transformer.transform(block)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
        expect(result.id).to eq('example-1')
        expect(result.delimiter).to eq('====')
      end
    end

    context 'when transforming a list' do
      it 'transforms a CoreModel list to AsciiDoc' do
        items = [
          Coradoc::CoreModel::ListItem.new(marker: '*', content: 'Item 1'),
          Coradoc::CoreModel::ListItem.new(marker: '*', content: 'Item 2')
        ]
        list = Coradoc::CoreModel::ListBlock.new(
          marker_type: 'asterisk',
          items: items
        )

        result = transformer.transform(list)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Unordered)
        expect(result.items.count).to eq(2)
      end
    end

    context 'when transforming a table' do
      it 'transforms a CoreModel table to AsciiDoc' do
        rows = [
          Coradoc::CoreModel::TableRow.new(
            cells: [
              Coradoc::CoreModel::TableCell.new(content: 'Cell 1'),
              Coradoc::CoreModel::TableCell.new(content: 'Cell 2')
            ]
          )
        ]
        table = Coradoc::CoreModel::Table.new(rows: rows)

        result = transformer.transform(table)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Table)
        expect(result.rows.count).to eq(1)
      end
    end

    context 'when transforming an image' do
      it 'transforms a CoreModel image to AsciiDoc' do
        image = Coradoc::CoreModel::Image.new(
          src: 'diagram.png',
          alt: 'System Diagram'
        )

        result = transformer.transform(image)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Image::BlockImage)
        expect(result.path).to eq('diagram.png')
        expect(result.alt).to eq('System Diagram')
      end
    end

    context 'when transforming an annotation' do
      it 'transforms a CoreModel annotation to AsciiDoc admonition' do
        annotation = Coradoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'note',
          content: 'This is important'
        )

        result = transformer.transform(annotation)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Admonition)
        expect(result.type).to eq('NOTE')
      end
    end

    context 'when transforming an array' do
      it 'transforms each element in the collection' do
        elements = [
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Section 1'
          ),
          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'section',
            level: 1,
            title: 'Section 2'
          )
        ]

        result = transformer.transform(elements)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::AsciiDoc::Model::Section)
      end
    end
  end
end
