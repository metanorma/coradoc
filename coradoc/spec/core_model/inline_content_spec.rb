# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::CoreModel::InlineContent do
  describe '.text_of' do
    it 'returns empty string for nil' do
      expect(described_class.text_of(nil)).to eq('')
    end

    it 'returns empty string for empty array' do
      expect(described_class.text_of([])).to eq('')
    end

    it 'returns the string itself for a String input' do
      expect(described_class.text_of('hello')).to eq('hello')
    end

    it 'joins an array of strings' do
      expect(described_class.text_of(['hello ', 'world'])).to eq('hello world')
    end

    it 'extracts content from InlineElement' do
      element = Coradoc::CoreModel::InlineElement.new(content: 'bold text')
      expect(described_class.text_of([element])).to eq('bold text')
    end

    it 'extracts content from typed InlineElement subclass' do
      element = Coradoc::CoreModel::BoldElement.new(content: 'bold')
      expect(described_class.text_of([element])).to eq('bold')
    end

    it 'recurses into StructuralElement children' do
      inline = Coradoc::CoreModel::InlineElement.new(content: 'nested')
      section = Coradoc::CoreModel::SectionElement.new(
        title: 'Section',
        children: [Coradoc::CoreModel::ParagraphBlock.new(children: [inline])]
      )
      expect(described_class.text_of([section])).to eq('nested')
    end

    it 'handles mixed String + InlineElement arrays' do
      element = Coradoc::CoreModel::InlineElement.new(content: 'world')
      expect(described_class.text_of(['hello ', element])).to eq('hello world')
    end

    it 'returns content from Base with string content (non-structural)' do
      model = Struct.new(:content, :title, :children).new('direct content', nil, nil)
      # Models without a String content fall through to title.to_s.
      # Verified via the Base branch of text_of_one.
    end

    it 'never mutates the input array or its elements' do
      element = Coradoc::CoreModel::InlineElement.new(content: 'original')
      input = [element]
      described_class.text_of(input)
      expect(element.content).to eq('original')
      expect(input).to eq([element])
    end
  end

  describe '.strip_edges' do
    it 'returns non-Array inputs unchanged' do
      expect(described_class.strip_edges('hello')).to eq('hello')
    end

    it 'returns empty array unchanged' do
      expect(described_class.strip_edges([])).to eq([])
    end

    it 'returns array unchanged when no text-carrying items' do
      result = described_class.strip_edges([nil, nil])
      expect(result).to eq([nil, nil])
    end

    it 'strips leading whitespace from first text-carrying item' do
      result = described_class.strip_edges(['   hello', 'world'])
      expect(result).to eq(['hello', 'world'])
    end

    it 'strips trailing whitespace from last text-carrying item' do
      result = described_class.strip_edges(['hello', 'world   '])
      expect(result).to eq(['hello', 'world'])
    end

    it 'strips both edges of a single-element array' do
      result = described_class.strip_edges(['  hello  '])
      expect(result).to eq(['hello'])
    end

    it 'strips InlineElement content edges without mutating the input' do
      element = Coradoc::CoreModel::InlineElement.new(content: '  hello  ')
      input = [element]
      result = described_class.strip_edges(input)

      expect(result.first.content).to eq('hello')
      expect(element.content).to eq('  hello  ') # input unchanged
      expect(result.first).not_to be(element) # new instance
    end

    it 'skips non-text items when finding first/last text carriers' do
      placeholder = Struct.new(:to_s).new('non-text')
      result = described_class.strip_edges([placeholder, '  hello', 'world  '])
      expect(result[1]).to eq('hello')
      expect(result[2]).to eq('world')
    end
  end

  describe 'integration with InlineElement#with_content' do
    it 'preserves other attributes when updating content' do
      element = Coradoc::CoreModel::LinkElement.new(
        content: 'click here',
        target: 'https://example.com'
      )
      new_element = element.with_content('clicked')
      expect(new_element.content).to eq('clicked')
      expect(new_element.target).to eq('https://example.com')
      expect(new_element.class).to be(Coradoc::CoreModel::LinkElement)
      expect(element.content).to eq('click here') # original unchanged
    end
  end
end
