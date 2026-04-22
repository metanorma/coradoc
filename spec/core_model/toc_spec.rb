# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/core_model'
require 'coradoc/core_model/toc_generator'

RSpec.describe Coradoc::CoreModel::Toc do
  describe '.new' do
    it 'creates a TOC with entries' do
      entry = Coradoc::CoreModel::TocEntry.new(id: 'section-1', title: 'Section 1', level: 1)
      toc = described_class.new(entries: [entry])

      expect(toc.entries.length).to eq(1)
      expect(toc.entries.first.title).to eq('Section 1')
    end

    it 'creates a TOC with configuration options' do
      toc = described_class.new(
        entries: [],
        min_level: 2,
        max_level: 4,
        numbered: true
      )

      expect(toc.min_level).to eq(2)
      expect(toc.max_level).to eq(4)
      expect(toc.numbered).to be true
    end

    it 'defaults min_level to 1' do
      toc = described_class.new(entries: [])

      expect(toc.min_level).to eq(1)
    end

    it 'defaults max_level to 6' do
      toc = described_class.new(entries: [])

      expect(toc.max_level).to eq(6)
    end
  end
end

RSpec.describe Coradoc::CoreModel::TocEntry do
  describe '.new' do
    it 'creates a TOC entry with id, title, and level' do
      entry = described_class.new(
        id: 'my-section',
        title: 'My Section',
        level: 2
      )

      expect(entry.id).to eq('my-section')
      expect(entry.title).to eq('My Section')
      expect(entry.level).to eq(2)
    end

    it 'creates a TOC entry with children' do
      child = described_class.new(id: 'child', title: 'Child', level: 2)
      parent = described_class.new(
        id: 'parent',
        title: 'Parent',
        level: 1,
        children: [child]
      )

      expect(parent.children.length).to eq(1)
      expect(parent.children.first.title).to eq('Child')
    end

    it 'creates a TOC entry with section number' do
      entry = described_class.new(
        id: 'section',
        title: 'Section',
        level: 1,
        number: '1.2.3'
      )

      expect(entry.number).to eq('1.2.3')
    end
  end
end

RSpec.describe Coradoc::CoreModel::TocGenerator do
  describe '.generate' do
    it 'generates TOC from document with sections' do
      section1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        id: 'section-1',
        title: 'Section 1',
        level: 1,
        children: []
      )
      section2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        id: 'section-2',
        title: 'Section 2',
        level: 1,
        children: []
      )
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [section1, section2]
      )

      toc = described_class.generate(doc)

      expect(toc).to be_a(Coradoc::CoreModel::Toc)
      expect(toc.entries.length).to eq(2)
      expect(toc.entries.first.title).to eq('Section 1')
      expect(toc.entries.last.title).to eq('Section 2')
    end

    it 'handles nested sections correctly' do
      subsection = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        id: 'subsection',
        title: 'Subsection',
        level: 2,
        children: []
      )
      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        id: 'main-section',
        title: 'Main Section',
        level: 1,
        children: [subsection]
      )
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [section]
      )

      toc = described_class.generate(doc)

      expect(toc.entries.length).to eq(1)
      expect(toc.entries.first.title).to eq('Main Section')
      expect(toc.entries.first.children.first.title).to eq('Subsection')
    end

    it 'returns nil for document without sections' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Text')
        ]
      )

      toc = described_class.generate(doc)

      expect(toc).to be_nil
    end

    it 'respects min_level option' do
      h1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'h1', title: 'H1', level: 1, children: []
      )
      h2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'h2', title: 'H2', level: 2, children: []
      )
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document', children: [h1, h2]
      )

      toc = described_class.generate(doc, min_level: 2)

      expect(toc.entries.first.title).to eq('H2')
    end

    it 'respects max_level option' do
      subsection = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'sub', title: 'Sub', level: 3, children: []
      )
      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'sec', title: 'Sec', level: 2, children: [subsection]
      )
      h1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'h1', title: 'H1', level: 1, children: [section]
      )
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document', children: [h1]
      )

      toc = described_class.generate(doc, max_level: 2)

      # Level 3 should not be included
      expect(toc.entries.first.children.first.children).to be_empty
    end

    it 'adds section numbers when numbered: true' do
      subsection = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 'sub', title: 'Sub', level: 2, children: []
      )
      section2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 's2', title: 'S2', level: 1, children: []
      )
      section1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section', id: 's1', title: 'S1', level: 1, children: [subsection]
      )
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document', children: [section1, section2]
      )

      toc = described_class.generate(doc, numbered: true)

      expect(toc.entries.first.number).to eq('1')
      expect(toc.entries.first.children.first.number).to eq('1.1')
      expect(toc.entries.last.number).to eq('2')
    end
  end
end
