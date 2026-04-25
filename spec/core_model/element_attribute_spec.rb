# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::ElementAttribute do
  describe '.new' do
    it 'creates an attribute with name and value' do
      attr = described_class.new(name: 'role', value: 'note')

      expect(attr.name).to eq('role')
      expect(attr.value).to eq('note')
    end

    it 'allows nil values' do
      attr = described_class.new(name: 'disabled', value: nil)

      expect(attr.name).to eq('disabled')
      expect(attr.value).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash with name as key' do
      attr = described_class.new(name: 'class', value: 'highlight')

      expect(attr.to_h).to eq({ 'class' => 'highlight' })
    end
  end

  describe '#to_s' do
    it 'returns attribute in name="value" format' do
      attr = described_class.new(name: 'id', value: 'section-1')

      expect(attr.to_s).to eq('"id="section-1""')
    end
  end

  describe 'lutaml-model serialization' do
    it 'serializes to hash' do
      attr = described_class.new(name: 'data-type', value: 'example')

      hash = attr.to_hash

      expect(hash['name']).to eq('data-type')
      expect(hash['value']).to eq('example')
    end

    it 'deserializes from hash' do
      hash = { 'name' => 'style', 'value' => 'warning' }

      attr = described_class.from_hash(hash)

      expect(attr.name).to eq('style')
      expect(attr.value).to eq('warning')
    end
  end

  describe 'equality' do
    it 'compares attributes by name and value' do
      attr1 = described_class.new(name: 'type', value: 'note')
      attr2 = described_class.new(name: 'type', value: 'note')
      attr3 = described_class.new(name: 'type', value: 'warning')

      expect(attr1.name).to eq(attr2.name)
      expect(attr1.value).to eq(attr2.value)
      expect(attr1.value).not_to eq(attr3.value)
    end
  end
end
