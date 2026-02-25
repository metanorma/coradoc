# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ToCoreModel do
  let(:transformer) { described_class.new }

  describe '#transform' do
    context 'when transforming a document' do
      it 'transforms an AsciiDoc document to CoreModel' do
        header = Coradoc::AsciiDoc::Model::Header.new(
          title: Coradoc::AsciiDoc::Model::Title.new(content: 'Test Document')
        )
        doc = Coradoc::AsciiDoc::Model::Document.new(
          header: header,
          sections: []
        )

        result = transformer.transform(doc)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('document')
        expect(result.title).to eq('Test Document')
      end
    end

    context 'when transforming a section' do
      it 'transforms an AsciiDoc section to CoreModel' do
        section = Coradoc::AsciiDoc::Model::Section.new(
          id: 'intro',
          level: 1,
          title: Coradoc::AsciiDoc::Model::Title.new(content: 'Introduction'),
          contents: []
        )

        result = transformer.transform(section)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('section')
        expect(result.level).to eq(1)
        expect(result.title).to eq('Introduction')
        expect(result.id).to eq('intro')
      end
    end

    context 'when transforming a block' do
      it 'transforms an AsciiDoc block to CoreModel' do
        block = Coradoc::AsciiDoc::Model::Block::Core.new(
          id: 'example-1',
          delimiter: '====',
          lines: ['Line 1', 'Line 2']
        )

        result = transformer.transform(block)

        expect(result).to be_a(Coradoc::CoreModel::Block)
        expect(result.delimiter_type).to eq('====')
        expect(result.content).to eq("Line 1\nLine 2")
      end
    end

    context 'when transforming an array' do
      it 'transforms each element in the collection' do
        sections = [
          Coradoc::AsciiDoc::Model::Section.new(
            level: 1,
            title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section 1')
          ),
          Coradoc::AsciiDoc::Model::Section.new(
            level: 1,
            title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section 2')
          )
        ]

        result = transformer.transform(sections)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::CoreModel::StructuralElement)
      end
    end
  end
end
