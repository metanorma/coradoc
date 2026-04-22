# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::List::Unordered do
  describe '#initialize' do
    it 'creates unordered list with items' do
      item = Coradoc::AsciiDoc::Model::List::Item.new(content: ['Item 1'])
      list = described_class.new(items: [item])

      expect(list.items).to eq([item])
    end

    it 'creates empty list' do
      list = described_class.new

      expect(list.items).to eq([])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::List::Ordered do
  describe '#initialize' do
    it 'creates ordered list with items' do
      item = Coradoc::AsciiDoc::Model::List::Item.new(content: ['First'])
      list = described_class.new(items: [item])

      expect(list.items).to eq([item])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::List::Definition do
  describe '#initialize' do
    it 'creates definition list with items' do
      item = Coradoc::AsciiDoc::Model::List::DefinitionItem.new(
        term: 'Word',
        definition: ['A unit of language']
      )
      list = described_class.new(items: [item])

      expect(list.items).to eq([item])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::List::Item do
  describe '#initialize' do
    it 'creates list item with content' do
      item = described_class.new(content: ['Item text'])

      expect(item.content).to eq(['Item text'])
    end

    it 'creates list item with marker' do
      item = described_class.new(content: ['Item text'], marker: '*')

      expect(item.marker).to eq('*')
    end

    it 'creates list item with id' do
      item = described_class.new(content: ['Item text'], id: 'item-1')

      expect(item.id).to eq('item-1')
    end
  end
end
