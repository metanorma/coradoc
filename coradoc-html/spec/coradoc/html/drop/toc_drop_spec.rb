# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/toc_drop'
require 'coradoc/html/drop/toc_entry_drop'

RSpec.describe Coradoc::Html::Drop::TocDrop do
  let(:entry) { CoreModel::TocEntry.new(title: 'Intro', level: 1, id: 'intro') }
  let(:model) { CoreModel::Toc.new(entries: [entry]) }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#entries' do
    it 'returns an array of TocEntryDrop' do
      entries = drop.entries
      expect(entries).to be_an(Array)
      expect(entries.first).to be_a(Coradoc::Html::Drop::TocEntryDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::TocEntryDrop do
  let(:model) do
    CoreModel::TocEntry.new(
      title: 'Introduction',
      level: 1,
      id: '_introduction',
      number: '1'
    )
  end
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#id' do
    it 'returns the entry id' do
      expect(drop.id).to eq('_introduction')
    end
  end

  describe '#title' do
    it 'returns escaped title' do
      expect(drop.title).to eq('Introduction')
    end
  end

  describe '#number' do
    it 'returns the section number' do
      expect(drop.number).to eq('1')
    end
  end

  describe '#level' do
    it 'returns the heading level' do
      expect(drop.level).to eq(1)
    end
  end

  describe '#children' do
    it 'returns an empty array when no children' do
      expect(drop.children).to eq([])
    end

    it 'returns an array of TocEntryDrop for nested entries' do
      child = CoreModel::TocEntry.new(title: 'Background', level: 2, id: '_bg')
      parent = CoreModel::TocEntry.new(title: 'Intro', level: 1, id: '_intro', children: [child])
      entry_drop = described_class.new(parent)
      expect(entry_drop.children).to be_an(Array)
      expect(entry_drop.children.first).to be_a(described_class)
    end
  end

  describe '#numbered_title' do
    it 'returns "N. Title" when numbered' do
      expect(drop.numbered_title).to eq('1. Introduction')
    end

    it 'returns plain title when not numbered' do
      entry = CoreModel::TocEntry.new(title: 'Intro', level: 1, id: 'intro')
      expect(described_class.new(entry).numbered_title).to eq('Intro')
    end
  end
end
