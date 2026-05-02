# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::DefinitionList do
  describe '.new' do
    it 'creates an empty definition list' do
      list = described_class.new
      expect(list.items).to be_nil.or be_empty
    end

    it 'creates a list with items' do
      item = Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])
      list = described_class.new(items: [item])

      expect(list.items.length).to eq(1)
      expect(list.items.first.term).to eq('API')
    end

    it 'accepts multiple items' do
      items = [
        Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface']),
        Coradoc::CoreModel::DefinitionItem.new(term: 'REST', definitions: ['Representational State Transfer'])
      ]
      list = described_class.new(items: items)

      expect(list.items.length).to eq(2)
    end
  end

  describe '#semantically_equivalent?' do
    it 'considers identical lists equivalent' do
      items = [Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])]
      list1 = described_class.new(items: items)
      list2 = described_class.new(items: [Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])])

      expect(list1.semantically_equivalent?(list2)).to be true
    end

    it 'considers different lists not equivalent' do
      list1 = described_class.new(items: [Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])])
      list2 = described_class.new(items: [Coradoc::CoreModel::DefinitionItem.new(term: 'REST', definitions: ['Representational State Transfer'])])

      expect(list1.semantically_equivalent?(list2)).to be false
    end
  end

  describe '#accept' do
    it 'accepts a visitor' do
      list = described_class.new(items: [Coradoc::CoreModel::DefinitionItem.new(term: 'API')])
      collector = Coradoc::Visitor::Collector.new(described_class)
      list.accept(collector)

      expect(collector.items).to include(list)
    end
  end
end
