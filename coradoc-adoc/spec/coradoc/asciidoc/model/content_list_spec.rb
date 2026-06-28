require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::ContentList do
  describe '.new' do
    it 'initializes with items' do
      content = described_class.new('Hello', 'World')
      expect(content.items).to all(be_a(Coradoc::AsciiDoc::Model::TextElement))
      expect(content.text).to eq('HelloWorld')
    end

    it 'flattens array inputs' do
      content = described_class.new(['Hello', [' ', 'World']])
      expect(content.text).to eq('Hello World')
      expect(content.size).to eq(3)
    end
  end

  describe '.from' do
    it 'returns the same instance if it is already a ContentList' do
      content = described_class.new('Hello')
      expect(described_class.from(content)).to be(content)
    end

    it 'creates a new ContentList from an array' do
      content = described_class.from(%w[Hello World])
      expect(content).to be_a(described_class)
      expect(content.text).to eq('HelloWorld')
    end

    it 'creates an empty ContentList from nil' do
      content = described_class.from(nil)
      expect(content).to be_empty
    end

    it 'creates a new ContentList from a single value' do
      content = described_class.from('Hello')
      expect(content.text).to eq('Hello')
    end
  end

  describe '#each' do
    it 'iterates over items' do
      content = described_class.new('Hello', 'World')
      items = []
      content.each { |item| items << item.content }
      expect(items).to eq(%w[Hello World])
    end
  end

  describe '#<<' do
    it 'returns a new ContentList with the appended item' do
      content = described_class.new('Hello')
      new_content = content << ' World'
      expect(new_content).to be_a(described_class)
      expect(new_content.text).to eq('Hello World')
      expect(content.text).to eq('Hello') # Immutability check
    end
  end

  describe '#find_type' do
    it 'returns items of the specified type' do
      bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: described_class.new('World'))
      content = described_class.new('Hello ', bold)

      found = content.find_type(Coradoc::AsciiDoc::Model::Inline::Bold)
      expect(found).to eq([bold])
    end
  end

  describe '#[]' do
    it 'returns the item at the given index' do
      content = described_class.new('Hello', 'World')
      expect(content[0].content).to eq('Hello')
      expect(content[1].content).to eq('World')
      expect(content[2]).to be_nil
    end
  end

  describe '#join' do
    it 'joins items with the specified separator' do
      content = described_class.new('Hello', 'World')
      expect(content.join(' ')).to eq('Hello World')
    end
  end

  describe '#+' do
    it 'concatenates two ContentLists' do
      content1 = described_class.new('Hello')
      content2 = described_class.new('World')
      combined = content1 + content2
      expect(combined.text).to eq('HelloWorld')
    end

    it 'concatenates with an array' do
      content1 = described_class.new('Hello')
      combined = content1 + ['World']
      expect(combined.text).to eq('HelloWorld')
    end
  end

  describe '#==' do
    it 'is equal to another ContentList with the same items' do
      content1 = described_class.new('Hello')
      content2 = described_class.new('Hello')
      expect(content1).to eq(content2)
    end

    it 'is not equal to another type' do
      content = described_class.new('Hello')
      expect(content).not_to eq('Hello')
    end
  end
end
