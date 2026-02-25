# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Builder do
  let(:builder) { described_class.new }

  describe '.build' do
    it 'builds a document from AST' do
      ast = {
        header: { title: 'Test Document' },
        sections: []
      }

      result = described_class.build(ast)

      expect(result).to be_a(Hash)
      expect(result[:header]).not_to be_nil
    end
  end

  describe '#build_document' do
    it 'builds a document with header and sections' do
      ast = {
        header: { title: 'Document Title' },
        sections: [{ section: { title: 'Introduction', level: '=' } }]
      }

      result = builder.build_document(ast)

      expect(result[:header][:title]).to eq('Document Title')
      expect(result[:sections]).to be_an(Array)
    end

    it 'handles empty AST' do
      result = builder.build_document({})

      expect(result).to be_a(Hash)
    end
  end

  describe '#build_element' do
    it 'builds a section element' do
      ast = { section: { title: 'Section Title', level: '==' } }

      result = builder.build_element(ast)

      expect(result[:type]).to eq(:section)
      expect(result[:title]).to eq('Section Title')
    end

    it 'builds a paragraph element' do
      ast = { paragraph: { lines: ['Paragraph text'] } }

      result = builder.build_element(ast)

      expect(result[:type]).to eq(:paragraph)
    end

    it 'returns nil for nil input' do
      expect(builder.build_element(nil)).to be_nil
    end
  end

  describe '#build_block' do
    it 'builds a generic block' do
      ast = { block: { delimiter: '====', lines: ['Content'] } }

      result = builder.build_block(ast)

      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.delimiter_type).to eq('====')
    end

    it 'builds an annotation block' do
      ast = {
        block: {
          delimiter: '****',
          lines: ['Note content'],
          attribute_list: { positional: ['NOTE'] }
        }
      }

      result = builder.build_block(ast)

      expect(result).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(result.annotation_type).to eq('note')
    end
  end

  describe '#build_list' do
    it 'builds an unordered list' do
      ast = {
        unordered: [
          { list_item: { marker: '*', text: 'Item 1' } },
          { list_item: { marker: '*', text: 'Item 2' } }
        ]
      }

      result = builder.build_list(ast)

      expect(result).to be_a(Coradoc::CoreModel::ListBlock)
      expect(result.marker_type).to eq('asterisk')
    end
  end

  describe '#build_list_item' do
    it 'builds a list item with content' do
      ast = { list_item: { marker: '*', text: 'Item content' } }

      result = builder.build_list_item(ast)

      expect(result).to be_a(Coradoc::CoreModel::ListItem)
      expect(result.marker).to eq('*')
      expect(result.content).to eq('Item content')
    end
  end

  describe '#build_inline' do
    it 'builds a bold inline element' do
      ast = { bold: 'important text' }

      result = builder.build_inline(ast)

      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('bold')
      expect(result.content).to eq('important text')
    end

    it 'builds an italic inline element' do
      ast = { italic: 'emphasized text' }

      result = builder.build_inline(ast)

      expect(result.format_type).to eq('italic')
    end
  end

  describe '#build_paragraph' do
    it 'builds a paragraph with lines' do
      ast = { paragraph: { lines: ['Line 1', 'Line 2'] } }

      result = builder.build_paragraph(ast)

      expect(result[:type]).to eq(:paragraph)
      expect(result[:content]).to be_an(Array)
    end
  end

  describe '#build_attributes' do
    it 'builds attributes from attribute list' do
      ast = {
        positional: %w[NOTE example],
        named: [{ key: 'role', value: 'important' }]
      }

      result = builder.build_attributes(ast)

      expect(result).to be_an(Array)
      expect(result.first[:positional]).to eq('NOTE')
    end
  end
end
