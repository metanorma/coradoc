# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ElementTransformers::BlockTransformer do
  describe '.transform_paragraph' do
    it 'transforms a basic paragraph with plain text' do
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        id: 'para-1',
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello world')]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(result.id).to eq('para-1')
      expect(result.content).to eq('Hello world')
      expect(result.lines).to eq(['Hello world'])
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Coradoc::CoreModel::TextContent)
    end

    it 'preserves source line structure for multi-line paragraphs' do
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'This is line one'),
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'of a paragraph'),
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'that spans three.')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coradoc::CoreModel::ParagraphBlock)
      # `content` is the rendered view — soft-wrapped lines joined with
      # spaces so they read as flowing prose.
      expect(result.content).to eq('This is line one of a paragraph that spans three.')
      # `lines` is the source-line view — each entry corresponds to one
      # line in the AsciiDoc source.
      expect(result.lines).to eq(['This is line one', 'of a paragraph', 'that spans three.'])
    end

    it 'filters out LineBreak and PageBreak items when extracting source lines' do
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Before'),
          Coradoc::AsciiDoc::Model::LineBreak.new,
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'After')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result.lines).to eq(%w[Before After])
    end

    it 'transforms a paragraph with inline elements' do
      inline_text = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
      para = Coradoc::AsciiDoc::Model::Paragraph.new(
        content: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          inline_text,
          Coradoc::AsciiDoc::Model::TextElement.new(content: ' world')
        ]
      )

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(result.content).to match(/Hello\s+bold\s*world/)
      # Inline elements between two TextElements do NOT synthesize a
      # soft-break space — the visitor only inserts " " between two
      # adjacent TextElements (i.e. real source line breaks). An
      # inline element sitting between two text runs means the source
      # had them on the same line.
      expect(result.children.size).to eq(3)
      expect(result.children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }).not_to be_nil
      expect(result.children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }.content).to eq('bold')
    end

    it 'handles empty content' do
      para = Coradoc::AsciiDoc::Model::Paragraph.new(content: [])

      result = described_class.transform_paragraph(para)

      expect(result).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(result.content).to eq('')
      expect(result.children).to be_empty
    end
  end

  describe '.transform_source_block' do
    it 'transforms a source block with language' do
      attr_list = Coradoc::AsciiDoc::Model::AttributeList.new(
        positional: [
          Coradoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'source'),
          Coradoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'ruby')
        ]
      )
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Example')])
      block = Coradoc::AsciiDoc::Model::Block::SourceCode.new(
        id: 'src-1',
        title: title,
        attributes: attr_list,
        lines: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'def test'),
          Coradoc::AsciiDoc::Model::LineBreak.new,
          Coradoc::AsciiDoc::Model::TextElement.new(content: '  true'),
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'end')
        ]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(result.id).to eq('src-1')
      expect(result.title).to eq('Example')
      expect(result.language).to eq('ruby')
      expect(result.content).to eq("def test\n  true\nend")
      expect(result.lines).to eq(['def test', '  true', 'end'])
    end

    it 'handles source block without language' do
      block = Coradoc::AsciiDoc::Model::Block::SourceCode.new(
        lines: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'plain code')]
      )

      result = described_class.transform_source_block(block)

      expect(result).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(result.language).to be_nil
      expect(result.content).to eq('plain code')
    end
  end

  describe '.transform_block' do
    it 'transforms a block with a string delimiter' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Note')])
      block = Coradoc::AsciiDoc::Model::Block::Core.new(
        id: 'blk-1',
        title: title,
        lines: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Note content')]
      )

      result = described_class.transform_block(block, '====')

      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.id).to eq('blk-1')
      expect(result.title).to eq('Note')
      expect(result.content).to eq('Note content')
      expect(result.lines).to eq(['Note content'])
      expect(result.block_semantic_type).to eq('example')
      expect(result.delimiter_type).to eq('====')
    end

    it 'transforms a block with a symbol semantic type' do
      block = Coradoc::AsciiDoc::Model::Block::Core.new(
        lines: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Sidebar content')]
      )

      result = described_class.transform_block(block, :sidebar)

      expect(result).to be_a(Coradoc::CoreModel::Block)
      expect(result.content).to eq('Sidebar content')
      expect(result.block_semantic_type.to_s).to eq('sidebar')
      expect(result.delimiter_type).to be_nil
    end
  end

  describe '.transform_typed_block' do
    it 'transforms into a specified class with simple lines' do
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Quote')])
      block = Coradoc::AsciiDoc::Model::Block::Quote.new(
        id: 'quote-1',
        title: title,
        lines: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'To be or not to be')]
      )

      result = described_class.transform_typed_block(
        block, Coradoc::CoreModel::QuoteBlock, { attribution: 'Shakespeare' }
      )

      expect(result).to be_a(Coradoc::CoreModel::QuoteBlock)
      expect(result.id).to eq('quote-1')
      expect(result.title).to eq('Quote')
      expect(result.content).to eq('To be or not to be')
      expect(result.attribution).to eq('Shakespeare')
      expect(result.children).to all(be_a(Coradoc::CoreModel::ParagraphBlock))
    end

    it 'groups consecutive soft-wrapped lines into a single paragraph' do
      block = Coradoc::AsciiDoc::Model::Block::Example.new(
        lines: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 1.'),
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'First paragraph line 2.'),
          Coradoc::AsciiDoc::Model::LineBreak.new,
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Second paragraph here.')
        ]
      )

      result = described_class.transform_typed_block(
        block, Coradoc::CoreModel::ExampleBlock
      )

      paragraphs = result.children
      expect(paragraphs.size).to eq(2)
      expect(paragraphs.all?(Coradoc::CoreModel::ParagraphBlock)).to be(true)
      expect(paragraphs[0].content).to eq('First paragraph line 1. First paragraph line 2.')
      expect(paragraphs[1].content).to eq('Second paragraph here.')
    end

    it 'transforms into a specified class with nested blocks' do
      nested = Coradoc::AsciiDoc::Model::Block::Core.new(
        lines: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Inner')]
      )
      block = Coradoc::AsciiDoc::Model::Block::Example.new(
        lines: [nested]
      )

      result = described_class.transform_typed_block(
        block, Coradoc::CoreModel::ExampleBlock
      )

      expect(result).to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(result.content).to be_nil
      expect(result.children).to be_an(Array)
      expect(result.children.size).to eq(1)
      expect(result.children.first).to be_a(Coradoc::CoreModel::Block)
    end
  end
end
