# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::AnnotationBlock do
  describe '.new' do
    it 'creates a NOTE annotation block' do
      block = described_class.new(
        annotation_type: 'note',
        delimiter_type: '****',
        content: 'This is important.'
      )

      expect(block.annotation_type).to eq('note')
      expect(block.delimiter_type).to eq('****')
      expect(block.content).to eq('This is important.')
    end

    it 'creates a WARNING annotation block with label' do
      block = described_class.new(
        annotation_type: 'warning',
        annotation_label: 'custom-label',
        content: 'Be careful!'
      )

      expect(block.annotation_type).to eq('warning')
      expect(block.annotation_label).to eq('custom-label')
    end

    it 'creates a reviewer annotation block' do
      block = described_class.new(
        annotation_type: 'reviewer',
        annotation_label: 'john.doe',
        content: 'Please review this.'
      )

      expect(block.annotation_type).to eq('reviewer')
      expect(block.annotation_label).to eq('john.doe')
    end
  end

  describe '#semantically_equivalent?' do
    let(:note1) do
      described_class.new(
        annotation_type: 'note',
        content: 'Important note'
      )
    end

    let(:note2) do
      described_class.new(
        annotation_type: 'note',
        content: 'Important note'
      )
    end

    let(:warning) do
      described_class.new(
        annotation_type: 'warning',
        content: 'Important note'
      )
    end

    let(:different_content) do
      described_class.new(
        annotation_type: 'note',
        content: 'Different note'
      )
    end

    it 'returns true for identical annotation blocks' do
      expect(note1.semantically_equivalent?(note2)).to be true
    end

    it 'returns false for different annotation types' do
      expect(note1.semantically_equivalent?(warning)).to be false
    end

    it 'returns false for different content' do
      expect(note1.semantically_equivalent?(different_content)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Block' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Block)
    end
  end
end
