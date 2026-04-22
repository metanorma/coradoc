# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Transform::ToCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(markdown_model) }

    context 'with Document' do
      let(:markdown_model) do
        Coradoc::Markdown::Document.new(
          id: 'test-doc',
          blocks: [
            Coradoc::Markdown::Heading.new(
              level: 1,
              text: 'Title'
            ),
            Coradoc::Markdown::Paragraph.new(
              text: 'Paragraph content'
            )
          ]
        )
      end

      it 'transforms to CoreModel::StructuralElement' do
        expect(transform).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(transform.element_type).to eq('document')
        expect(transform.id).to eq('test-doc')
        expect(transform.title).to eq('Title')
      end

      it 'transforms children blocks' do
        expect(transform.children).to be_an(Array)
        expect(transform.children.length).to eq(2)
      end
    end

    context 'with Heading' do
      let(:markdown_model) do
        Coradoc::Markdown::Heading.new(
          level: 2,
          text: 'Section Title'
        )
      end

      it 'transforms to CoreModel::StructuralElement with section type' do
        expect(transform).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(transform.element_type).to eq('section')
        expect(transform.level).to eq(2)
        expect(transform.title).to eq('Section Title')
      end
    end

    context 'with Paragraph' do
      let(:markdown_model) do
        Coradoc::Markdown::Paragraph.new(text: 'Some paragraph text')
      end

      it 'transforms to CoreModel::Block with paragraph type' do
        expect(transform).to be_a(Coradoc::CoreModel::Block)
        expect(transform.element_type).to eq('paragraph')
        expect(transform.content).to eq('Some paragraph text')
      end
    end

    context 'with CodeBlock' do
      let(:markdown_model) do
        Coradoc::Markdown::CodeBlock.new(
          code: "def hello\n  puts 'world'\nend",
          language: 'ruby'
        )
      end

      it 'transforms to CoreModel::Block with code delimiter' do
        expect(transform).to be_a(Coradoc::CoreModel::Block)
        expect(transform.delimiter_type).to eq('```')
        expect(transform.content).to eq("def hello\n  puts 'world'\nend")
        expect(transform.language).to eq('ruby')
      end
    end

    context 'with Blockquote' do
      let(:markdown_model) do
        Coradoc::Markdown::Blockquote.new(content: 'Quoted text')
      end

      it 'transforms to CoreModel::Block with blockquote delimiter' do
        expect(transform).to be_a(Coradoc::CoreModel::Block)
        expect(transform.delimiter_type).to eq('>')
        expect(transform.content).to eq('Quoted text')
      end
    end

    context 'with List (unordered)' do
      let(:markdown_model) do
        Coradoc::Markdown::List.new(
          ordered: false,
          items: [
            Coradoc::Markdown::ListItem.new(text: 'Item 1'),
            Coradoc::Markdown::ListItem.new(text: 'Item 2')
          ]
        )
      end

      it 'transforms to CoreModel::ListBlock with unordered marker type' do
        expect(transform).to be_a(Coradoc::CoreModel::ListBlock)
        expect(transform.marker_type).to eq('unordered')
        expect(transform.items.length).to eq(2)
        expect(transform.items.first.content).to eq('Item 1')
      end
    end

    context 'with List (ordered)' do
      let(:markdown_model) do
        Coradoc::Markdown::List.new(
          ordered: true,
          items: [
            Coradoc::Markdown::ListItem.new(text: 'First')
          ]
        )
      end

      it 'transforms to CoreModel::ListBlock with ordered marker type' do
        expect(transform).to be_a(Coradoc::CoreModel::ListBlock)
        expect(transform.marker_type).to eq('ordered')
      end
    end

    context 'with Image' do
      let(:markdown_model) do
        Coradoc::Markdown::Image.new(
          src: 'https://example.com/image.png',
          alt: 'Alt text'
        )
      end

      it 'transforms to CoreModel::Image' do
        expect(transform).to be_a(Coradoc::CoreModel::Image)
        expect(transform.src).to eq('https://example.com/image.png')
        expect(transform.alt).to eq('Alt text')
      end
    end

    context 'with Link' do
      let(:markdown_model) do
        Coradoc::Markdown::Link.new(
          url: 'https://example.com',
          text: 'Example'
        )
      end

      it 'transforms to CoreModel::InlineElement with link type' do
        expect(transform).to be_a(Coradoc::CoreModel::InlineElement)
        expect(transform.format_type).to eq('link')
        expect(transform.target).to eq('https://example.com')
        expect(transform.content).to eq('Example')
      end
    end

    context 'with Emphasis (italic)' do
      let(:markdown_model) do
        Coradoc::Markdown::Emphasis.new(text: 'italic text')
      end

      it 'transforms to CoreModel::InlineElement with italic type' do
        expect(transform).to be_a(Coradoc::CoreModel::InlineElement)
        expect(transform.format_type).to eq('italic')
        expect(transform.content).to eq('italic text')
      end
    end

    context 'with Strong (bold)' do
      let(:markdown_model) do
        Coradoc::Markdown::Strong.new(text: 'bold text')
      end

      it 'transforms to CoreModel::InlineElement with bold type' do
        expect(transform).to be_a(Coradoc::CoreModel::InlineElement)
        expect(transform.format_type).to eq('bold')
        expect(transform.content).to eq('bold text')
      end
    end

    context 'with Code (inline)' do
      let(:markdown_model) do
        Coradoc::Markdown::Code.new(text: 'inline code')
      end

      it 'transforms to CoreModel::InlineElement with monospace type' do
        expect(transform).to be_a(Coradoc::CoreModel::InlineElement)
        expect(transform.format_type).to eq('monospace')
        expect(transform.content).to eq('inline code')
      end
    end

    context 'with HorizontalRule' do
      let(:markdown_model) do
        Coradoc::Markdown::HorizontalRule.new
      end

      it 'transforms to CoreModel::Block with hr delimiter' do
        expect(transform).to be_a(Coradoc::CoreModel::Block)
        expect(transform.delimiter_type).to eq('---')
      end
    end

    context 'with Text' do
      let(:markdown_model) do
        Coradoc::Markdown::Text.new(content: 'plain text')
      end

      it 'returns the content as string' do
        expect(transform).to eq('plain text')
      end
    end

    context 'with Array' do
      let(:markdown_model) do
        [
          Coradoc::Markdown::Paragraph.new(text: 'Para 1'),
          Coradoc::Markdown::Paragraph.new(text: 'Para 2')
        ]
      end

      it 'transforms each element' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(2)
        expect(transform.first).to be_a(Coradoc::CoreModel::Block)
        expect(transform.last).to be_a(Coradoc::CoreModel::Block)
      end
    end

    context 'with unknown type' do
      let(:markdown_model) { 'plain string' }

      it 'returns the value unchanged' do
        expect(transform).to eq('plain string')
      end
    end
  end
end
