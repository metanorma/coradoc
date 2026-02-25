# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::InlineElement do
  describe '.new' do
    it 'creates a bold inline element' do
      element = described_class.new(
        format_type: 'bold',
        constrained: true,
        content: 'important text'
      )

      expect(element.format_type).to eq('bold')
      expect(element.constrained).to be true
      expect(element.content).to eq('important text')
    end

    it 'creates an italic inline element' do
      element = described_class.new(
        format_type: 'italic',
        constrained: false,
        content: 'emphasized'
      )

      expect(element.format_type).to eq('italic')
      expect(element.constrained).to be false
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

    it 'defaults constrained to true' do
      element = described_class.new(format_type: 'bold', content: 'text')

      expect(element.constrained).to be true
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
end
