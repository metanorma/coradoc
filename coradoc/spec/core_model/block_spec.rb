# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Block do
  describe '.new' do
    it 'creates a block with semantic type and content' do
      block = described_class.new(
        block_semantic_type: :example,
        content: 'Example content'
      )

      expect(block.block_semantic_type).to eq('example')
      expect(block.content).to eq('Example content')
    end

    it 'creates a block with lines' do
      block = described_class.new(
        block_semantic_type: :source_code,
        lines: ['line 1', 'line 2', 'line 3']
      )

      expect(block.lines).to eq(['line 1', 'line 2', 'line 3'])
    end

    it 'accepts delimiter_type for round-trip fidelity' do
      block = described_class.new(
        delimiter_type: '====',
        content: 'Example content'
      )

      expect(block.delimiter_type).to eq('====')
      expect(block.content).to eq('Example content')
    end
  end

  describe '#semantically_equivalent?' do
    let(:block1) do
      described_class.new(
        block_semantic_type: :example,
        content: 'Same content'
      )
    end

    let(:block2) do
      described_class.new(
        block_semantic_type: :example,
        content: 'Same content'
      )
    end

    let(:block3) do
      described_class.new(
        block_semantic_type: :sidebar,
        content: 'Same content'
      )
    end

    it 'returns true for blocks with same type and content' do
      expect(block1.semantically_equivalent?(block2)).to be true
    end

    it 'returns false for blocks with different semantic types' do
      expect(block1.semantically_equivalent?(block3)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
