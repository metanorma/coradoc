# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/DescribeClass - This is a feature spec for the API facade
RSpec.describe 'Developer Experience API' do
  # Load coradoc core and asciidoc

  describe 'Coradoc.parse' do
    it 'parses AsciiDoc text to CoreModel' do
      text = "= Document Title\n\n== Section\n\nContent here."

      result = Coradoc.parse(text, format: :asciidoc)

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(result.element_type).to eq('document')
    end

    it 'raises error for unregistered format' do
      expect do
        Coradoc.parse('text', format: :unknown)
      end.to raise_error(Coradoc::UnsupportedFormatError, /not registered/)
    end

    it 'lists available formats in error message' do
      expect do
        Coradoc.parse('text', format: :unknown)
      end.to raise_error(/Available formats:.*asciidoc/)
    end
  end

  describe 'Coradoc.convert' do
    it 'converts AsciiDoc to AsciiDoc (round-trip)' do
      input = "= Title\n\n== Section\n\nParagraph."

      result = Coradoc.convert(input, from: :asciidoc, to: :asciidoc)

      expect(result).to include('Title')
      expect(result).to include('Section')
      expect(result).to include('Paragraph')
    end

    it 'preserves document structure in conversion' do
      input = <<~ADOC
        = Complex Document

        == Introduction

        Some intro text.

        * Item 1
        * Item 2

        == Details

        More details here.
      ADOC

      result = Coradoc.convert(input, from: :asciidoc, to: :asciidoc)

      expect(result).to include('Introduction')
      expect(result).to include('Item 1')
      expect(result).to include('Details')
    end

    it 'raises error for unknown source format' do
      expect do
        Coradoc.convert('text', from: :unknown, to: :asciidoc)
      end.to raise_error(Coradoc::UnsupportedFormatError)
    end

    it 'raises error for unknown target format' do
      expect do
        Coradoc.convert('text', from: :asciidoc, to: :unknown)
      end.to raise_error(Coradoc::UnsupportedFormatError)
    end
  end

  describe 'Coradoc.serialize' do
    it 'serializes CoreModel to AsciiDoc' do
      core = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'My Document',
        children: []
      )

      result = Coradoc.serialize(core, to: :asciidoc)

      expect(result).to include('My Document')
    end
  end

  describe 'Coradoc.to_core' do
    it 'returns CoreModel as-is' do
      core = Coradoc::CoreModel::Block.new(content: 'test')

      result = Coradoc.to_core(core)

      expect(result).to eq(core)
    end

    it 'transforms AsciiDoc model to CoreModel' do
      adoc = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello')]
      )

      result = Coradoc.to_core(adoc)

      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.element_type).to eq('paragraph')
    end
  end

  describe 'format registration' do
    it 'lists registered formats' do
      expect(Coradoc.registered_formats).to include(:asciidoc)
    end

    it 'returns format module' do
      expect(Coradoc.get_format(:asciidoc)).to eq(Coradoc::AsciiDoc)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
