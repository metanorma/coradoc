# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Block do
  describe '.new' do
    it 'creates a block with delimiter and content' do
      block = described_class.new(
        delimiter_type: '====',
        delimiter_length: 4,
        content: 'Example content'
      )

      expect(block.delimiter_type).to eq('====')
      expect(block.delimiter_length).to eq(4)
      expect(block.content).to eq('Example content')
    end

    it 'creates a block with lines' do
      block = described_class.new(
        delimiter_type: '----',
        lines: ['line 1', 'line 2', 'line 3']
      )

      expect(block.lines).to eq(['line 1', 'line 2', 'line 3'])
    end

    it 'defaults delimiter_length to 4' do
      block = described_class.new(delimiter_type: '====')

      expect(block.delimiter_length).to eq(4)
    end
  end

  describe '#semantically_equivalent?' do
    let(:block1) do
      described_class.new(
        delimiter_type: '====',
        delimiter_length: 4,
        content: 'Same content'
      )
    end

    let(:block2) do
      described_class.new(
        delimiter_type: '====',
        delimiter_length: 4,
        content: 'Same content'
      )
    end

    let(:block3) do
      described_class.new(
        delimiter_type: '====',
        delimiter_length: 6, # Different length
        content: 'Same content'
      )
    end

    let(:block4) do
      described_class.new(
        delimiter_type: '****', # Different type
        content: 'Same content'
      )
    end

    it 'returns true for blocks with same type and content' do
      expect(block1.semantically_equivalent?(block2)).to be true
    end

    it 'returns true for blocks with different delimiter lengths' do
      expect(block1.semantically_equivalent?(block3)).to be true
    end

    it 'returns false for blocks with different delimiter types' do
      expect(block1.semantically_equivalent?(block4)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
