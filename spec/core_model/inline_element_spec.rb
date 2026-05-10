# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::InlineElement do
  describe '.new' do
    it 'creates a bold inline element' do
      element = described_class.new(
        format_type: 'bold',
        content: 'important text'
      )

      expect(element.format_type).to eq('bold')
      expect(element.content).to eq('important text')
    end

    it 'creates an italic inline element' do
      element = described_class.new(
        format_type: 'italic',
        content: 'emphasized'
      )

      expect(element.format_type).to eq('italic')
    end

    it 'creates an inline element with nested elements' do
      nested = described_class.new(format_type: 'italic', content: 'nested')
      element = described_class.new(
        format_type: 'bold',
        content: 'bold ',
        nested_elements: [nested]
      )

      expect(element.nested_elements).to be_an(Array)
      expect(element.nested_elements.first.format_type).to eq('italic')
    end

    it 'creates element without format_type' do
      element = described_class.new(content: 'text')
      expect(element.content).to eq('text')
    end
  end

  describe '#semantically_equivalent?' do
    let(:bold1) { described_class.new(format_type: 'bold', content: 'text') }
    let(:bold2) { described_class.new(format_type: 'bold', content: 'text') }
    let(:italic) { described_class.new(format_type: 'italic', content: 'text') }
    let(:different_content) { described_class.new(format_type: 'bold', content: 'other') }

    it 'returns true for identical elements' do
      expect(bold1.semantically_equivalent?(bold2)).to be true
    end

    it 'returns false for different format types' do
      expect(bold1.semantically_equivalent?(italic)).to be false
    end

    it 'returns false for different content' do
      expect(bold1.semantically_equivalent?(different_content)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end

  describe 'ChildrenContent integration' do
    it 'has children array' do
      element = described_class.new(format_type: 'bold', content: 'text', children: ['a'])
      expect(element.children).to eq(['a'])
    end

    it 'returns content via renderable_content when no children' do
      element = described_class.new(format_type: 'bold', content: 'bold text')
      expect(element.renderable_content).to eq('bold text')
    end

    it 'returns children via renderable_content when children have InlineElements' do
      inner = described_class.new(format_type: 'italic', content: 'inner')
      element = described_class.new(
        format_type: 'bold',
        content: 'outer',
        children: ['prefix ', inner]
      )
      expect(element.renderable_content).to eq(['prefix ', inner])
    end

    it 'flattens children to plain text via flat_text' do
      inner = described_class.new(format_type: 'italic', content: 'world')
      element = described_class.new(
        format_type: 'bold',
        children: ['hello ', inner]
      )
      expect(element.flat_text).to eq('hello world')
    end
  end

  describe 'FORMAT_TYPES' do
    it 'includes all core format types' do
      %w[bold italic monospace underline strikethrough subscript superscript
         highlight link xref stem footnote hard_line_break].each do |type|
        expect(described_class::FORMAT_TYPES).to include(type)
      end
    end

    it 'is frozen' do
      expect(described_class::FORMAT_TYPES).to be_frozen
    end
  end
end
