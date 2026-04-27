# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::StructuralElement do
  describe '#heading_level' do
    it 'returns the level when set' do
      element = described_class.new(element_type: 'section', level: 3, title: 'Subsection')

      expect(element.heading_level).to eq(3)
    end

    it 'defaults to 1 when level is nil' do
      element = described_class.new(element_type: 'section', title: 'Untitled')

      expect(element.heading_level).to eq(1)
    end
  end

  describe '#section?' do
    it 'returns true for element_type section' do
      element = described_class.new(element_type: 'section')

      expect(element).to be_section
    end

    it 'returns false for element_type document' do
      element = described_class.new(element_type: 'document')

      expect(element).not_to be_section
    end

    it 'returns false when element_type is nil' do
      element = described_class.new

      expect(element).not_to be_section
    end
  end

  describe '#document?' do
    it 'returns true for element_type document' do
      element = described_class.new(element_type: 'document')

      expect(element).to be_document
    end

    it 'returns false for element_type section' do
      element = described_class.new(element_type: 'section')

      expect(element).not_to be_document
    end
  end
end
