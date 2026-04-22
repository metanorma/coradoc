# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Title do
  describe '#initialize' do
    it 'creates title with content' do
      title = described_class.new(content: 'Chapter 1')

      expect(title.to_s).to eq('Chapter 1')
    end

    it 'creates title with level' do
      title = described_class.new(content: 'Section', level_int: 2)

      expect(title.level_int).to eq(2)
    end

    it 'creates title with array content' do
      text_element = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello')
      title = described_class.new(content: [text_element])

      expect(title.to_s).to eq('Hello')
    end

    it 'creates title with id' do
      title = described_class.new(content: 'Section', id: 'intro')

      expect(title.id).to eq('intro')
    end

    it 'creates title with style' do
      title = described_class.new(content: 'Section', style: 'discrete')

      expect(title.style).to eq('discrete')
    end
  end

  describe '#to_s' do
    it 'returns string content' do
      title = described_class.new(content: 'My Title')

      expect(title.to_s).to eq('My Title')
    end

    it 'returns joined array content' do
      elem1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello ')
      elem2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'World')
      title = described_class.new(content: [elem1, elem2])

      expect(title.to_s).to eq('Hello World')
    end

    it 'returns empty string for nil content' do
      title = described_class.new(content: nil)

      expect(title.to_s).to eq('')
    end
  end

  describe '#level_str' do
    it 'returns single = for level 0' do
      title = described_class.new(content: 'Title', level_int: 0)

      expect(title.level_str).to eq('=')
    end

    it 'returns == for level 1' do
      title = described_class.new(content: 'Title', level_int: 1)

      expect(title.level_str).to eq('==')
    end

    it 'returns ====== for level 5' do
      title = described_class.new(content: 'Title', level_int: 5)

      expect(title.level_str).to eq('======')
    end

    it 'returns ====== for levels > 5' do
      title = described_class.new(content: 'Title', level_int: 10)

      expect(title.level_str).to eq('======')
    end

    it 'returns empty string for nil level' do
      title = described_class.new(content: 'Title')

      expect(title.level_str).to eq('')
    end
  end

  describe '#style_str' do
    it 'returns empty string for nil level' do
      title = described_class.new(content: 'Title', style: 'discrete')

      expect(title.style_str).to eq('')
    end

    it 'returns style for level <= 5' do
      title = described_class.new(content: 'Title', level_int: 2, style: 'discrete')

      expect(title.style_str).to eq("[discrete]\n")
    end

    it 'includes level attribute for level > 5' do
      title = described_class.new(content: 'Title', level_int: 6, style: 'discrete')

      expect(title.style_str).to eq("[discrete,level=6]\n")
    end

    it 'returns level only when no style for level > 5' do
      title = described_class.new(content: 'Title', level_int: 7)

      expect(title.style_str).to eq("[level=7]\n")
    end
  end

  describe '#text' do
    it 'is an alias for content' do
      title = described_class.new(content: 'My Title')

      expect(title.text).to eq(title.content)
    end
  end
end
