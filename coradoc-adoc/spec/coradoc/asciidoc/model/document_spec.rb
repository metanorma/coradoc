# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Document do
  describe '#initialize' do
    it 'creates document with default values' do
      document = described_class.new

      expect(document.document_attributes).to be_a(Coradoc::AsciiDoc::Model::DocumentAttributes)
      expect(document.header).to be_a(Coradoc::AsciiDoc::Model::Header)
      expect(document.header.title).to be_a(Coradoc::AsciiDoc::Model::Title)
      expect(document.sections).to eq([])
    end

    it 'accepts custom header' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: 'Test Document', level_int: 0)
      header = Coradoc::AsciiDoc::Model::Header.new(title: title)
      document = described_class.new(header: header)

      expect(document.header).to eq(header)
      expect(document.header.title.to_s).to eq('Test Document')
    end

    it 'accepts custom document attributes' do
      doc_attrs = Coradoc::AsciiDoc::Model::DocumentAttributes.new
      document = described_class.new(document_attributes: doc_attrs)

      expect(document.document_attributes).to eq(doc_attrs)
    end

    it 'accepts custom sections' do
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section 1', level_int: 1)
      )
      document = described_class.new(sections: [section])

      expect(document.sections).to eq([section])
    end
  end

  describe '#[] and #[]=' do
    it 'accesses sections by index' do
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section 1', level_int: 1)
      )
      document = described_class.new(sections: [section])

      expect(document[0]).to eq(section)
    end

    it 'sets sections by index' do
      document = described_class.new
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section 1', level_int: 1)
      )

      document[0] = section
      expect(document.sections[0]).to eq(section)
    end
  end

  describe '.from_ast' do
    it 'creates document from AST elements' do
      doc_attrs = Coradoc::AsciiDoc::Model::DocumentAttributes.new
      header = Coradoc::AsciiDoc::Model::Header.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Test', level_int: 0)
      )
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 1)
      )

      document = described_class.from_ast([doc_attrs, header, section])

      expect(document.document_attributes).to eq(doc_attrs)
      expect(document.header).to eq(header)
      expect(document.sections).to eq([section])
    end

    it 'handles missing document attributes' do
      header = Coradoc::AsciiDoc::Model::Header.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Test', level_int: 0)
      )
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 1)
      )

      document = described_class.from_ast([header, section])

      expect(document.document_attributes).to be_a(Coradoc::AsciiDoc::Model::DocumentAttributes)
      expect(document.header).to eq(header)
      expect(document.sections).to eq([section])
    end

    it 'handles missing header' do
      section = Coradoc::AsciiDoc::Model::Section.new(
        title: Coradoc::AsciiDoc::Model::Title.new(content: 'Section', level_int: 1)
      )

      document = described_class.from_ast([section])

      expect(document.header).to be_a(Coradoc::AsciiDoc::Model::Header)
      expect(document.sections).to eq([section])
    end

    it 'handles empty elements' do
      document = described_class.from_ast([])

      expect(document.document_attributes).to be_a(Coradoc::AsciiDoc::Model::DocumentAttributes)
      expect(document.header).to be_a(Coradoc::AsciiDoc::Model::Header)
      expect(document.sections).to eq([])
    end
  end

  describe 'polymorphic sections' do
    it 'accepts different section types' do
      paragraph = Coradoc::AsciiDoc::Model::Paragraph.new(content: ['Text'])
      admonition = Coradoc::AsciiDoc::Model::Admonition.new(type: 'NOTE', content: ['Note'])
      table = Coradoc::AsciiDoc::Model::Table.new

      document = described_class.new(sections: [paragraph, admonition, table])

      expect(document.sections).to eq([paragraph, admonition, table])
    end
  end
end
