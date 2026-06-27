# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Postprocessor do
  describe '.process' do
    it 'returns the tree unchanged' do
      tree = [CoreModel::Block.new(block_semantic_type: :paragraph, content: 'test')]
      result = described_class.process(tree)
      expect(result).to eq(tree)
    end

    it 'returns nil unchanged' do
      result = described_class.process(nil)
      expect(result).to be_nil
    end
  end

  describe '#process' do
    it 'returns the tree passed to initialize' do
      tree = CoreModel::Block.new(block_semantic_type: :paragraph, content: 'hello')
      instance = described_class.new(tree)
      expect(instance.process).to eq(tree)
    end
  end
end
