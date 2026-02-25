# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Transform::FromCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(core_model) }

    context 'with StructuralElement (document)' do
      let(:core_model) do
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          id: 'doc-1',
          title: 'Document Title',
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'Introduction paragraph'
            )
          ]
        )
      end

      it 'transforms to Markdown::Document' do
        expect(transform).to be_a(Coradoc::Markdown::Document)
        expect(transform.id).to eq('doc-1')
        expect(transform.blocks).to be_an(Array)
      end
    end

    context 'with StructuralElement (section)' do
      let(:core_model) do
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          level: 2,
          title: 'Section Title',
          children: []
        )
      end

      it 'transforms to Markdown::Heading' do
        expect(transform).to be_a(Coradoc::Markdown::Heading)
        expect(transform.level).to eq(2)
        expect(transform.text).to eq('Section Title')
      end
    end

    context 'with Block (paragraph)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'This is a paragraph.'
        )
      end

      it 'transforms to Markdown::Paragraph' do
        expect(transform).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.text).to eq('This is a paragraph.')
      end
    end

    context 'with Block (code block)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '```',
          content: "puts 'hello'",
          language: 'ruby'
        )
      end

      it 'transforms to Markdown::CodeBlock' do
        expect(transform).to be_a(Coradoc::Markdown::CodeBlock)
        expect(transform.code).to eq("puts 'hello'")
        expect(transform.language).to eq('ruby')
      end
    end

    context 'with Block (blockquote)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '>',
          content: 'Quoted content'
        )
      end

      it 'transforms to Markdown::Blockquote' do
        expect(transform).to be_a(Coradoc::Markdown::Blockquote)
        expect(transform.content).to eq('Quoted content')
      end
    end

    context 'with Block (horizontal rule)' do
      let(:core_model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'block',
          delimiter_type: '---'
        )
      end

      it 'transforms to Markdown::HorizontalRule' do
        expect(transform).to be_a(Coradoc::Markdown::HorizontalRule)
      end
    end

    context 'with ListBlock (unordered)' do
      let(:core_model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'First item', marker: '*'),
            Coradoc::CoreModel::ListItem.new(content: 'Second item', marker: '*')
          ]
        )
      end

      it 'transforms to Markdown::List with unordered type' do
        expect(transform).to be_a(Coradoc::Markdown::List)
        expect(transform.ordered).to be false
        expect(transform.items.length).to eq(2)
        expect(transform.items.first.text).to eq('First item')
      end
    end

    context 'with ListBlock (ordered)' do
      let(:core_model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'ordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'First', marker: '1.')
          ]
        )
      end

      it 'transforms to Markdown::List with ordered type' do
        expect(transform).to be_a(Coradoc::Markdown::List)
        expect(transform.ordered).to be true
      end
    end

    context 'with Table' do
      let(:core_model) do
        Coradoc::CoreModel::Table.new(
          rows: [
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'Header 1', header: true),
                Coradoc::CoreModel::TableCell.new(content: 'Header 2', header: true)
              ]
            ),
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'Cell 1', header: false),
                Coradoc::CoreModel::TableCell.new(content: 'Cell 2', header: false)
              ]
            )
          ]
        )
      end

      it 'transforms to Markdown::Table with headers and rows' do
        expect(transform).to be_a(Coradoc::Markdown::Table)
        expect(transform.headers).to eq(['Header 1', 'Header 2'])
        expect(transform.rows.length).to eq(1)
        expect(transform.rows.first).to eq('Cell 1 | Cell 2')
      end
    end

    context 'with Image' do
      let(:core_model) do
        Coradoc::CoreModel::Image.new(
          src: 'image.png',
          alt: 'An image'
        )
      end

      it 'transforms to Markdown::Image' do
        expect(transform).to be_a(Coradoc::Markdown::Image)
        expect(transform.src).to eq('image.png')
        expect(transform.alt).to eq('An image')
      end
    end

    context 'with InlineElement (link)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'link',
          target: 'https://example.com',
          content: 'Click here'
        )
      end

      it 'transforms to Markdown::Link' do
        expect(transform).to be_a(Coradoc::Markdown::Link)
        expect(transform.url).to eq('https://example.com')
        expect(transform.text).to eq('Click here')
      end
    end

    context 'with InlineElement (bold)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )
      end

      it 'transforms to Markdown::Strong' do
        expect(transform).to be_a(Coradoc::Markdown::Strong)
        expect(transform.text).to eq('bold text')
      end
    end

    context 'with InlineElement (italic)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'italic',
          content: 'italic text'
        )
      end

      it 'transforms to Markdown::Emphasis' do
        expect(transform).to be_a(Coradoc::Markdown::Emphasis)
        expect(transform.text).to eq('italic text')
      end
    end

    context 'with InlineElement (monospace)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'monospace',
          content: 'code'
        )
      end

      it 'transforms to Markdown::Code' do
        expect(transform).to be_a(Coradoc::Markdown::Code)
        expect(transform.text).to eq('code')
      end
    end

    context 'with InlineElement (unknown type)' do
      let(:core_model) do
        Coradoc::CoreModel::InlineElement.new(
          format_type: 'unknown',
          content: 'some text'
        )
      end

      it 'returns the content as string' do
        expect(transform).to eq('some text')
      end
    end

    context 'with Array' do
      let(:core_model) do
        [
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'Para 1'
          ),
          Coradoc::CoreModel::Block.new(
            element_type: 'paragraph',
            content: 'Para 2'
          )
        ]
      end

      it 'transforms each element' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(2)
        expect(transform.first).to be_a(Coradoc::Markdown::Paragraph)
        expect(transform.last).to be_a(Coradoc::Markdown::Paragraph)
      end
    end

    context 'with unknown type' do
      let(:core_model) { 'plain string' }

      it 'returns the value unchanged' do
        expect(transform).to eq('plain string')
      end
    end
  end
end
