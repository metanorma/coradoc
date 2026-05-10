# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::StructuralElement do
  describe '#heading_level' do
    it 'returns the level when set' do
      element = Coradoc::CoreModel::SectionElement.new(level: 3, title: 'Subsection')

      expect(element.heading_level).to eq(3)
    end

    it 'defaults to 1 when level is nil' do
      element = Coradoc::CoreModel::SectionElement.new(title: 'Untitled')

      expect(element.heading_level).to eq(1)
    end
  end

  describe '#section?' do
    it 'returns true for SectionElement' do
      element = Coradoc::CoreModel::SectionElement.new

      expect(element).to be_section
    end

    it 'returns false for DocumentElement' do
      element = Coradoc::CoreModel::DocumentElement.new

      expect(element).not_to be_section
    end

    it 'returns false for base StructuralElement' do
      element = described_class.new

      expect(element).not_to be_section
    end
  end

  describe '#document?' do
    it 'returns true for DocumentElement' do
      element = Coradoc::CoreModel::DocumentElement.new

      expect(element).to be_document
    end

    it 'returns false for SectionElement' do
      element = Coradoc::CoreModel::SectionElement.new

      expect(element).not_to be_document
    end
  end
end
