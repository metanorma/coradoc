# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/definition_list_drop'
require 'coradoc/html/drop/definition_item_drop'

RSpec.describe Coradoc::Html::Drop::DefinitionListDrop do
  let(:item) { CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface']) }
  let(:model) { CoreModel::DefinitionList.new(id: 'glossary', items: [item]) }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#id' do
    it 'returns the list id' do
      expect(drop.id).to eq('glossary')
    end
  end

  describe '#title' do
    it 'returns nil when no title' do
      expect(drop.title).to be_nil
    end

    it 'returns escaped title' do
      dl = CoreModel::DefinitionList.new(title: 'Glossary')
      expect(described_class.new(dl).title).to eq('Glossary')
    end
  end

  describe '#items' do
    it 'returns an array of DefinitionItemDrop' do
      items = drop.items
      expect(items).to be_an(Array)
      expect(items.first).to be_a(Coradoc::Html::Drop::DefinitionItemDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::DefinitionItemDrop do
  let(:model) { CoreModel::DefinitionItem.new(term: 'HTML', definitions: ['Markup language']) }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#term' do
    it 'returns escaped term text' do
      expect(drop.term).to eq('HTML')
    end

    it 'strips [[anchor]] prefix from term' do
      item = CoreModel::DefinitionItem.new(term: '[[my-term]]My Term')
      expect(described_class.new(item).term).to eq('My Term')
    end
  end

  describe '#term_id' do
    it 'extracts id from [[...]] prefix' do
      item = CoreModel::DefinitionItem.new(term: '[[my-term]]My Term')
      expect(described_class.new(item).term_id).to eq('my-term')
    end

    it 'returns nil without anchor prefix' do
      expect(drop.term_id).to be_nil
    end
  end

  describe '#definitions' do
    it 'returns an array of liquid-converted definitions' do
      defs = drop.definitions
      expect(defs).to be_an(Array)
      expect(defs.size).to eq(1)
    end
  end
end
