# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/list_block_drop'
require 'coradoc/html/drop/list_item_drop'

RSpec.describe Coradoc::Html::Drop::ListBlockDrop do
  let(:model) { CoreModel::ListBlock.new(marker_type: 'unordered') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#html_tag' do
    it 'returns ul for unordered' do
      expect(drop.html_tag).to eq('ul')
    end

    it 'returns ol for ordered' do
      ol = CoreModel::ListBlock.new(marker_type: 'ordered')
      expect(described_class.new(ol).html_tag).to eq('ol')
    end

    it 'returns dl for definition' do
      dl = CoreModel::ListBlock.new(marker_type: 'definition')
      expect(described_class.new(dl).html_tag).to eq('dl')
    end
  end

  describe '#id' do
    it 'returns the model id' do
      list = CoreModel::ListBlock.new(marker_type: 'unordered', id: 'my-list')
      expect(described_class.new(list).id).to eq('my-list')
    end
  end

  describe '#title' do
    it 'returns escaped title' do
      list = CoreModel::ListBlock.new(marker_type: 'unordered', title: 'My List')
      expect(described_class.new(list).title).to eq('My List')
    end
  end

  describe '#items' do
    it 'returns an array of ListItemDrop instances' do
      item = CoreModel::ListItem.new(content: [CoreModel::TextContent.new(text: 'Item')])
      list = CoreModel::ListBlock.new(marker_type: 'unordered', items: [item])
      drop = described_class.new(list)
      items = drop.items
      expect(items).to be_an(Array)
      expect(items.first).to be_a(Coradoc::Html::Drop::ListItemDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::ListItemDrop do
  let(:model) { CoreModel::ListItem.new(content: 'Item 1') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#content' do
    it 'returns liquid-converted content' do
      expect(drop.content).to eq('Item 1')
    end
  end

  describe '#nested_list' do
    it 'returns nil when no nested list' do
      expect(drop.nested_list).to be_nil
    end

    it 'returns a ListBlockDrop when nested list exists' do
      nested = CoreModel::ListBlock.new(marker_type: 'ordered')
      item = CoreModel::ListItem.new(
        content: [CoreModel::TextContent.new(text: 'Item')],
        nested_list: nested
      )
      drop = described_class.new(item)
      expect(drop.nested_list).to be_a(Coradoc::Html::Drop::ListBlockDrop)
    end
  end
end
