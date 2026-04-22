# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::ListBlock do
  describe '.new' do
    let(:item1) { Coradoc::CoreModel::ListItem.new(marker: '*', content: 'First') }
    let(:item2) { Coradoc::CoreModel::ListItem.new(marker: '*', content: 'Second') }

    it 'creates an unordered list with items' do
      list = described_class.new(
        marker_type: 'asterisk',
        marker_level: 1,
        items: [item1, item2]
      )

      expect(list.marker_type).to eq('asterisk')
      expect(list.marker_level).to eq(1)
      expect(list.items).to be_an(Array)
      expect(list.items.count).to eq(2)
    end

    it 'defaults marker_level to 1' do
      list = described_class.new(marker_type: 'asterisk', items: [])

      expect(list.marker_level).to eq(1)
    end
  end

  describe '#semantically_equivalent?' do
    let(:item) { Coradoc::CoreModel::ListItem.new(marker: '*', content: 'Item') }
    let(:list1) { described_class.new(marker_type: 'asterisk', marker_level: 1, items: [item]) }
    let(:list2) { described_class.new(marker_type: 'asterisk', marker_level: 2, items: [item]) }
    let(:list3) { described_class.new(marker_type: 'numbered', marker_level: 1, items: [item]) }

    it 'returns true for lists with same marker type and items' do
      # Different marker_level shouldn't affect equivalence
      expect(list1.semantically_equivalent?(list2)).to be true
    end

    it 'returns false for lists with different marker types' do
      expect(list1.semantically_equivalent?(list3)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end

RSpec.describe Coradoc::CoreModel::ListItem do
  describe '.new' do
    it 'creates a simple list item' do
      item = described_class.new(marker: '*', content: 'Item text')

      expect(item.marker).to eq('*')
      expect(item.content).to eq('Item text')
    end

    it 'creates a list item with nested list' do
      nested_list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'asterisk',
        marker_level: 2,
        items: []
      )
      item = described_class.new(
        marker: '*',
        content: 'Parent',
        nested_list: nested_list
      )

      expect(item.nested_list).to be_a(Coradoc::CoreModel::ListBlock)
      expect(item.nested_list.marker_level).to eq(2)
    end
  end

  describe '#semantically_equivalent?' do
    let(:item1) { described_class.new(marker: '*', content: 'Item') }
    let(:item2) { described_class.new(marker: '*', content: 'Item') }
    let(:item3) { described_class.new(marker: '-', content: 'Item') } # Different marker
    let(:item4) { described_class.new(marker: '*', content: 'Different') } # Different content

    it 'returns true for items with same content' do
      expect(item1.semantically_equivalent?(item2)).to be true
    end

    it "returns true for items with different markers (marker doesn't affect semantics)" do
      expect(item1.semantically_equivalent?(item3)).to be true
    end

    it 'returns false for items with different content' do
      expect(item1.semantically_equivalent?(item4)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
