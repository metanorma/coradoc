# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::MetadataEntry do
  describe '.new' do
    it 'creates an entry with key and value' do
      entry = described_class.new(key: 'source_line', value: '42')

      expect(entry.key).to eq('source_line')
      expect(entry.value).to eq('42')
    end

    it 'allows nil values' do
      entry = described_class.new(key: 'optional', value: nil)

      expect(entry.key).to eq('optional')
      expect(entry.value).to be_nil
    end
  end

  describe 'lutaml-model serialization' do
    it 'serializes to hash' do
      entry = described_class.new(key: 'parser_version', value: '1.0.0')

      hash = entry.to_hash

      expect(hash['key']).to eq('parser_version')
      expect(hash['value']).to eq('1.0.0')
    end

    it 'deserializes from hash' do
      hash = { 'key' => 'author', 'value' => 'John Doe' }

      entry = described_class.from_hash(hash)

      expect(entry.key).to eq('author')
      expect(entry.value).to eq('John Doe')
    end
  end

  describe 'equality' do
    it 'compares entries by key and value' do
      entry1 = described_class.new(key: 'version', value: '1.0')
      entry2 = described_class.new(key: 'version', value: '1.0')
      entry3 = described_class.new(key: 'version', value: '2.0')

      expect(entry1.key).to eq(entry2.key)
      expect(entry1.value).to eq(entry2.value)
      expect(entry1.value).not_to eq(entry3.value)
    end
  end
end
