# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::ListItem do
  describe '.new' do
    it 'creates a list item with content' do
      item = described_class.new(content: 'List item text')

      expect(item.content).to eq('List item text')
    end

    it 'creates a list item with marker' do
      item = described_class.new(content: 'Item', marker: '*')

      expect(item.marker).to eq('*')
    end

    it 'creates a list item with ordered marker' do
      item = described_class.new(content: 'First', marker: '1.')

      expect(item.marker).to eq('1.')
    end

    it 'defaults marker to nil' do
      item = described_class.new(content: 'Item')

      expect(item.marker).to be_nil
    end
  end

  describe '#content' do
    it 'returns the list item content' do
      item = described_class.new(content: 'Test content')

      expect(item.content).to eq('Test content')
    end
  end

  describe '#marker' do
    it 'returns the marker when set' do
      item = described_class.new(content: 'Item', marker: '-')

      expect(item.marker).to eq('-')
    end

    it 'returns nil when marker not set' do
      item = described_class.new(content: 'Item')

      expect(item.marker).to be_nil
    end
  end
end
