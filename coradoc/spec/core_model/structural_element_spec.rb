# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::StructuralElement do
  describe 'base class' do
    it 'returns nil element_type for base StructuralElement' do
      element = described_class.new(level: 1, title: 'Generic')
      expect(element.element_type).to be_nil
    end

    it 'returns false for all type predicates' do
      element = described_class.new
      expect(element.section?).to be false
      expect(element.document?).to be false
      expect(element.preamble?).to be false
      expect(element.header?).to be false
    end
  end

  describe Coradoc::CoreModel::SectionElement do
    it 'creates a section element' do
      section = described_class.new(
        level: 1,
        title: 'Introduction',
        id: 'intro'
      )

      expect(section.element_type).to eq('section')
      expect(section.section?).to be true
      expect(section.level).to eq(1)
      expect(section.title).to eq('Introduction')
    end

    it 'inherits from StructuralElement' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::StructuralElement)
    end

    it 'defaults heading_level to 1' do
      expect(described_class.new.heading_level).to eq(1)
    end
  end

  describe Coradoc::CoreModel::DocumentElement do
    it 'creates a document element with children' do
      child = Coradoc::CoreModel::SectionElement.new(level: 1, title: 'Child')
      document = described_class.new(
        title: 'My Document',
        children: [child]
      )

      expect(document.element_type).to eq('document')
      expect(document.document?).to be true
      expect(document.children).to be_an(Array)
      expect(document.children.first.title).to eq('Child')
    end

    it 'inherits from StructuralElement' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::StructuralElement)
    end
  end

  describe Coradoc::CoreModel::PreambleElement do
    it 'creates a preamble element' do
      preamble = described_class.new(content: 'Before the first section')
      expect(preamble.element_type).to eq('preamble')
      expect(preamble.preamble?).to be true
    end
  end

  describe Coradoc::CoreModel::HeaderElement do
    it 'creates a header element' do
      header = described_class.new(title: 'Document Title')
      expect(header.element_type).to eq('header')
      expect(header.header?).to be true
    end
  end

  describe '#semantically_equivalent?' do
    let(:section1) { Coradoc::CoreModel::SectionElement.new(level: 1, title: 'Introduction') }
    let(:section2) { Coradoc::CoreModel::SectionElement.new(level: 1, title: 'Introduction') }
    let(:section3) { Coradoc::CoreModel::SectionElement.new(level: 2, title: 'Introduction') }
    let(:section4) { Coradoc::CoreModel::SectionElement.new(level: 1, title: 'Different Title') }

    it 'returns true for identical sections' do
      expect(section1.semantically_equivalent?(section2)).to be true
    end

    it 'returns false for sections with different levels' do
      expect(section1.semantically_equivalent?(section3)).to be false
    end

    it 'returns false for sections with different titles' do
      expect(section1.semantically_equivalent?(section4)).to be false
    end

    it 'returns false for different subclasses' do
      document = Coradoc::CoreModel::DocumentElement.new(level: 1, title: 'Introduction')
      expect(section1.semantically_equivalent?(document)).to be false
    end
  end

  describe 'inheritance' do
    it 'StructuralElement inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
