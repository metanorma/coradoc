# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Callout do
  describe '.new' do
    it 'sets index and content' do
      callout = described_class.new(index: 2, content: 'Explains line two')

      expect(callout.index).to eq(2)
      expect(callout.content).to eq('Explains line two')
    end

    it 'defaults to nil for both attributes' do
      callout = described_class.new

      expect(callout.index).to be_nil
      expect(callout.content).to be_nil
    end
  end

  describe '#semantically_equivalent?' do
    it 'is equivalent when index and content match' do
      a = described_class.new(index: 1, content: 'note')
      b = described_class.new(index: 1, content: 'note')

      expect(a).to be_semantically_equivalent(b)
    end

    it 'is not equivalent when index differs' do
      a = described_class.new(index: 1, content: 'note')
      b = described_class.new(index: 2, content: 'note')

      expect(a).not_to be_semantically_equivalent(b)
    end

    it 'is not equivalent when content differs' do
      a = described_class.new(index: 1, content: 'one thing')
      b = described_class.new(index: 1, content: 'another')

      expect(a).not_to be_semantically_equivalent(b)
    end
  end
end

RSpec.describe Coradoc::CoreModel::Block do
  describe 'callouts attribute' do
    it 'defaults to an empty collection' do
      block = described_class.new(content: 'code')

      expect(block.callouts).to eq([])
    end

    it 'accepts typed Callout instances' do
      callout = Coradoc::CoreModel::Callout.new(index: 1, content: 'note')
      block = described_class.new(content: 'code', callouts: [callout])

      expect(block.callouts.size).to eq(1)
      expect(block.callouts.first).to be_a(Coradoc::CoreModel::Callout)
      expect(block.callouts.first.index).to eq(1)
    end
  end
end
