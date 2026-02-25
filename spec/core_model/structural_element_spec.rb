# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::StructuralElement do
  describe '.new' do
    it 'creates a section element' do
      section = described_class.new(
        element_type: 'section',
        level: 1,
        title: 'Introduction',
        id: 'intro'
      )

      expect(section.element_type).to eq('section')
      expect(section.level).to eq(1)
      expect(section.title).to eq('Introduction')
      expect(section.id).to eq('intro')
    end

    it 'creates a document element with children' do
      child = described_class.new(element_type: 'section', level: 1, title: 'Child')
      document = described_class.new(
        element_type: 'document',
        title: 'My Document',
        children: [child]
      )

      expect(document.element_type).to eq('document')
      expect(document.children).to be_an(Array)
      expect(document.children.first.title).to eq('Child')
    end
  end

  describe '#semantically_equivalent?' do
    let(:section1) do
      described_class.new(
        element_type: 'section',
        level: 1,
        title: 'Introduction'
      )
    end

    let(:section2) do
      described_class.new(
        element_type: 'section',
        level: 1,
        title: 'Introduction'
      )
    end

    let(:section3) do
      described_class.new(
        element_type: 'section',
        level: 2, # Different level
        title: 'Introduction'
      )
    end

    let(:section4) do
      described_class.new(
        element_type: 'section',
        level: 1,
        title: 'Different Title'
      )
    end

    it 'returns true for identical sections' do
      expect(section1.semantically_equivalent?(section2)).to be true
    end

    it 'returns false for sections with different levels' do
      expect(section1.semantically_equivalent?(section3)).to be false
    end

    it 'returns false for sections with different titles' do
      expect(section1.semantically_equivalent?(section4)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
