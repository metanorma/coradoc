# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Metadata do
  describe '.new' do
    it 'creates metadata with nil entries by default' do
      metadata = described_class.new

      expect(metadata.entries).to be_nil
    end

    it 'creates metadata with entries' do
      entries = [
        Coradoc::CoreModel::MetadataEntry.new(key: 'source', value: 'file.adoc'),
        Coradoc::CoreModel::MetadataEntry.new(key: 'line', value: '10')
      ]

      metadata = described_class.new(entries: entries)

      expect(metadata.entries.length).to eq(2)
    end
  end

  describe '#[] and #[]=' do
    it 'gets value by key' do
      metadata = described_class.new(entries: [
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'author', value: 'Jane')
                                     ])

      expect(metadata['author']).to eq('Jane')
      expect(metadata['nonexistent']).to be_nil
    end

    it 'sets value by key' do
      metadata = described_class.new

      metadata['version'] = '1.0'

      expect(metadata['version']).to eq('1.0')
      expect(metadata.entries.length).to eq(1)
    end

    it 'updates existing entry' do
      metadata = described_class.new(entries: [
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'status', value: 'draft')
                                     ])

      metadata['status'] = 'final'

      expect(metadata['status']).to eq('final')
      expect(metadata.entries.length).to eq(1)
    end
  end

  describe '#key?' do
    it 'returns true if key exists' do
      metadata = described_class.new(entries: [
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'lang', value: 'en')
                                     ])

      expect(metadata.key?('lang')).to be true
      expect(metadata.key?('missing')).to be false
    end
  end

  describe '#keys' do
    it 'returns all keys' do
      metadata = described_class.new(entries: [
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'a', value: '1'),
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'b', value: '2')
                                     ])

      expect(metadata.keys).to contain_exactly('a', 'b')
    end
  end

  describe '#to_h' do
    it 'converts entries to hash' do
      metadata = described_class.new(entries: [
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'type', value: 'document'),
                                       Coradoc::CoreModel::MetadataEntry.new(key: 'level', value: 'section')
                                     ])

      hash = metadata.to_h

      expect(hash).to eq({ 'type' => 'document', 'level' => 'section' })
    end
  end
end
