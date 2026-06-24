# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Mirror::Handlers::Inline do
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe '.process' do
    it 'processes simple marks' do
      bold = Coradoc::CoreModel::BoldElement.new(content: 'bold text')
      element = Coradoc::CoreModel::ParagraphBlock.new(
        children: [bold]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('bold text')
      expect(nodes.first.marks.first.type).to eq('strong')
    end

    it 'processes text content' do
      text = Coradoc::CoreModel::TextContent.new(text: 'plain text')
      element = Coradoc::CoreModel::ParagraphBlock.new(
        children: [text]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('plain text')
    end

    it 'processes semantic marks like links' do
      link = Coradoc::CoreModel::LinkElement.new(
        target: 'https://example.com',
        content: 'Example'
      )
      element = Coradoc::CoreModel::ParagraphBlock.new(
        children: [link]
      )

      nodes = described_class.process(element, context: context)
      expect(nodes.length).to eq(1)
      expect(nodes.first.type).to eq('text')
      expect(nodes.first.text).to eq('Example')
      expect(nodes.first.marks.first.type).to eq('link')
      expect(nodes.first.marks.first.attrs.href).to eq('https://example.com')
    end
  end

  describe '.text_content' do
    it 'returns nil for empty text' do
      text = Coradoc::CoreModel::TextContent.new(text: '')
      node = described_class.text_content(text, context: context)
      expect(node).to be_nil
    end

    it 'returns text node' do
      text = Coradoc::CoreModel::TextContent.new(text: 'hello')
      node = described_class.text_content(text, context: context)
      expect(node.type).to eq('text')
      expect(node.text).to eq('hello')
    end
  end

  describe '.call' do
    it 'handles inline element directly' do
      italic = Coradoc::CoreModel::ItalicElement.new(content: 'italic text')
      node = described_class.call(italic, context: context)

      expect(node.type).to eq('text')
      expect(node.text).to eq('italic text')
      expect(node.marks.first.type).to eq('emphasis')
    end
  end
end
