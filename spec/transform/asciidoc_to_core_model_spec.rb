# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Transform::AsciiDocToCoreModel do
  describe '.transform' do
    it 'transforms an AsciiDoc paragraph to CoreModel' do
      paragraph = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: ['Hello, World!']
      )

      result = described_class.transform(paragraph)

      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.element_type).to eq('paragraph')
    end

    it 'transforms an AsciiDoc section to CoreModel' do
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Introduction', level_int: 1)
      )

      result = described_class.transform(section)

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(result.element_type).to eq('section')
      expect(result.title).to eq('Introduction')
    end

    it 'transforms an AsciiDoc document to CoreModel' do
      document = Coradoc::AsciiDoc::Model::Document.new(
        header: Coradoc::AsciiDoc::Model::Header.new(
          title: Coradoc::AsciiDoc::Model::Title.new(content: 'Test Document')
        )
      )

      result = described_class.transform(document)

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(result.element_type).to eq('document')
    end

    it 'transforms inline elements correctly' do
      bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(
        content: ['bold text']
      )

      result = described_class.transform(bold)

      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('bold')
    end

    it 'transforms lists correctly' do
      list = Coradoc::AsciiDoc::Model::List::Unordered.new(
        items: [
          Coradoc::AsciiDoc::Model::List::Item.new(content: ['Item 1'])
        ]
      )

      result = described_class.transform(list)

      expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('unordered')
    end
  end

  describe '.available?' do
    it 'returns true when coradoc-adoc is loaded' do
      expect(described_class.available?).to be(true)
    end
  end
end
