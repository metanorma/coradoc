# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Paragraph do
  describe '#initialize' do
    it 'creates paragraph with content' do
      text = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello World')
      paragraph = described_class.new(content: [text])

      expect(paragraph.content).to eq([text])
    end

    it 'creates paragraph with string content' do
      paragraph = described_class.new(content: ['Simple text'])

      expect(paragraph.content).to eq(['Simple text'])
    end

    it 'creates paragraph with id' do
      paragraph = described_class.new(id: 'intro-para', content: ['Text'])

      expect(paragraph.id).to eq('intro-para')
    end

    it 'creates paragraph with trailing_newlines' do
      paragraph = described_class.new(content: ['Text'], trailing_newlines: "\n\n\n")

      expect(paragraph.trailing_newlines).to eq("\n\n\n")
    end

    it 'creates paragraph with title' do
      paragraph = described_class.new(content: ['Text'], title: 'My Paragraph')

      expect(paragraph.title).to eq('My Paragraph')
    end

    it 'creates paragraph with attributes' do
      attrs = Coradoc::AsciiDoc::Model::AttributeList.new
      paragraph = described_class.new(content: ['Text'], attributes: attrs)

      expect(paragraph.attributes).to eq(attrs)
    end

    it 'creates paragraph with tdsinglepara flag' do
      paragraph = described_class.new(content: ['Text'], tdsinglepara: true)

      expect(paragraph.tdsinglepara).to be true
    end
  end

  describe 'default values' do
    it 'has empty content by default' do
      paragraph = described_class.new

      expect(paragraph.content).to eq([])
    end

    it 'has empty attributes by default' do
      paragraph = described_class.new

      expect(paragraph.attributes).to be_a(Coradoc::AsciiDoc::Model::AttributeList)
    end

    it 'has tdsinglepara false by default' do
      paragraph = described_class.new

      expect(paragraph.tdsinglepara).to be false
    end

    it 'has nil trailing_newlines by default' do
      paragraph = described_class.new

      expect(paragraph.trailing_newlines).to be_nil
    end
  end

  describe 'content handling' do
    it 'accepts mixed content' do
      text1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello ')
      bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'World')
      paragraph = described_class.new(content: [text1, bold, '!'])

      expect(paragraph.content).to eq([text1, bold, '!'])
    end
  end
end
