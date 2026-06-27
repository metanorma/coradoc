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

    it 'dispatches RawInlineElement to a typed raw_inline node' do
      raw = Coradoc::CoreModel::RawInlineElement.new(
        content: '<abbr title="x">WYSIWYM</abbr>'
      )
      node = described_class.call(raw, context: context)

      expect(node).to be_a(Coradoc::Mirror::Node::RawInline)
      expect(node.type).to eq('raw_inline')
      expect(node.text).to eq('<abbr title="x">WYSIWYM</abbr>')
    end

    it 'returns nil for empty raw content' do
      raw = Coradoc::CoreModel::RawInlineElement.new(content: '')
      node = described_class.call(raw, context: context)
      expect(node).to be_nil
    end
  end

  describe 'round-trip raw_inline' do
    it 'mirror_json → CoreModel → mirror_json preserves the typed node' do
      original = Coradoc::CoreModel::ParagraphBlock.new(
        children: [Coradoc::CoreModel::RawInlineElement.new(content: '<b>x</b>')]
      )
      json1 = Coradoc.serialize(original, to: :mirror_json)

      node = Coradoc::Mirror.from_hash(JSON.parse(json1))
      document = Coradoc::Mirror::MirrorToCoreModel.new.call(node)

      raw = Array(document.children).find do |child|
        child.is_a?(Coradoc::CoreModel::RawInlineElement)
      end
      expect(raw).not_to be_nil
      expect(raw.content).to eq('<b>x</b>')

      json2 = Coradoc.serialize(document, to: :mirror_json)
      expect(json2).to eq(json1)
    end
  end
end
