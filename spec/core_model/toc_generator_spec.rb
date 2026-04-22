# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/core_model'
require 'coradoc/core_model/toc_generator'

RSpec.describe Coradoc::CoreModel::TocGenerator do
  describe '.generate' do
    # Helper to create section elements
    def create_section(id:, title:, level:, children: [])
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        id: id,
        title: title,
        level: level,
        children: children
      )
    end

    def create_document(children:)
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: children
      )
    end

    describe 'basic TOC generation' do
      it 'generates TOC from document with sections' do
        section1 = create_section(id: 'section-1', title: 'Section 1', level: 1)
        section2 = create_section(id: 'section-2', title: 'Section 2', level: 1)
        doc = create_document(children: [section1, section2])

        toc = described_class.generate(doc)

        expect(toc).to be_a(Coradoc::CoreModel::Toc)
        expect(toc.entries.length).to eq(2)
        expect(toc.entries.first.title).to eq('Section 1')
        expect(toc.entries.last.title).to eq('Section 2')
      end

      it 'returns nil for document without sections' do
        doc = create_document(children: [
                                Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Text')
                              ])

        toc = described_class.generate(doc)

        expect(toc).to be_nil
      end

      it 'returns nil for empty document' do
        doc = create_document(children: [])

        toc = described_class.generate(doc)

        expect(toc).to be_nil
      end
    end

    describe 'nested sections' do
      it 'handles nested sections correctly' do
        subsection = create_section(id: 'subsection', title: 'Subsection', level: 2)
        section = create_section(id: 'main-section', title: 'Main Section', level: 1,
                                 children: [subsection])
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.title).to eq('Main Section')
        expect(toc.entries.first.children.first.title).to eq('Subsection')
      end

      it 'handles deeply nested sections' do
        h4 = create_section(id: 'h4', title: 'H4', level: 4)
        h3 = create_section(id: 'h3', title: 'H3', level: 3, children: [h4])
        h2 = create_section(id: 'h2', title: 'H2', level: 2, children: [h3])
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [h2])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc)

        expect(toc.entries.first.title).to eq('H1')
        expect(toc.entries.first.children.first.title).to eq('H2')
        expect(toc.entries.first.children.first.children.first.title).to eq('H3')
        expect(toc.entries.first.children.first.children.first.children.first.title).to eq('H4')
      end

      it 'handles sibling sections at different levels' do
        h2a = create_section(id: 'h2a', title: 'H2A', level: 2)
        h2b = create_section(id: 'h2b', title: 'H2B', level: 2)
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [h2a, h2b])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc)

        expect(toc.entries.first.children.length).to eq(2)
        expect(toc.entries.first.children.map(&:title)).to contain_exactly('H2A', 'H2B')
      end
    end

    describe 'level filtering' do
      it 'respects min_level option' do
        h1 = create_section(id: 'h1', title: 'H1', level: 1)
        h2 = create_section(id: 'h2', title: 'H2', level: 2)
        doc = create_document(children: [h1, h2])

        toc = described_class.generate(doc, min_level: 2)

        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.title).to eq('H2')
      end

      it 'respects max_level option' do
        subsection = create_section(id: 'sub', title: 'Sub', level: 3)
        section = create_section(id: 'sec', title: 'Sec', level: 2, children: [subsection])
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [section])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc, max_level: 2)

        # Level 3 should not be included
        expect(toc.entries.first.children.first.children).to be_empty
      end

      it 'respects both min_level and max_level' do
        # Create a hierarchy where we filter to levels 2-3
        h3 = create_section(id: 'h3', title: 'H3', level: 3)
        h2 = create_section(id: 'h2', title: 'H2', level: 2, children: [h3])
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [h2])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc, min_level: 2, max_level: 3)

        # With min_level: 2, H2 becomes the top-level entry
        # H3 is included as a child of H2
        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.title).to eq('H2')
        expect(toc.entries.first.children.first.title).to eq('H3')
      end

      it 'returns nil when no sections match level range' do
        h1 = create_section(id: 'h1', title: 'H1', level: 1)
        doc = create_document(children: [h1])

        toc = described_class.generate(doc, min_level: 3)

        expect(toc).to be_nil
      end
    end

    describe 'numbered sections' do
      it 'adds section numbers when numbered: true' do
        subsection = create_section(id: 'sub', title: 'Sub', level: 2)
        section2 = create_section(id: 's2', title: 'S2', level: 1)
        section1 = create_section(id: 's1', title: 'S1', level: 1, children: [subsection])
        doc = create_document(children: [section1, section2])

        toc = described_class.generate(doc, numbered: true)

        expect(toc.entries.first.number).to eq('1')
        expect(toc.entries.first.children.first.number).to eq('1.1')
        expect(toc.entries.last.number).to eq('2')
      end

      it 'does not add numbers by default' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.first.number).to be_nil
      end

      it 'resets numbering at each level' do
        h2a = create_section(id: 'h2a', title: 'H2A', level: 2)
        h2b = create_section(id: 'h2b', title: 'H2B', level: 2)
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [h2a, h2b])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc, numbered: true)

        expect(toc.entries.first.number).to eq('1')
        expect(toc.entries.first.children[0].number).to eq('1.1')
        expect(toc.entries.first.children[1].number).to eq('1.2')
      end

      it 'handles complex nested numbering' do
        h3 = create_section(id: 'h3', title: 'H3', level: 3)
        h2 = create_section(id: 'h2', title: 'H2', level: 2, children: [h3])
        h1 = create_section(id: 'h1', title: 'H1', level: 1, children: [h2])
        doc = create_document(children: [h1])

        toc = described_class.generate(doc, numbered: true)

        expect(toc.entries.first.number).to eq('1')
        expect(toc.entries.first.children.first.number).to eq('1.1')
        expect(toc.entries.first.children.first.children.first.number).to eq('1.1.1')
      end
    end

    describe 'entry attributes' do
      it 'preserves section id in TOC entry' do
        section = create_section(id: 'my-custom-id', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.first.id).to eq('my-custom-id')
      end

      it 'preserves section title in TOC entry' do
        section = create_section(id: 's1', title: 'My Section Title', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.first.title).to eq('My Section Title')
      end

      it 'sets correct level in TOC entry' do
        section = create_section(id: 's1', title: 'Section', level: 3)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.first.level).to eq(3)
      end
    end

    describe 'TOC configuration options' do
      it 'sets min_level on generated TOC' do
        section = create_section(id: 's1', title: 'Section', level: 2)
        doc = create_document(children: [section])

        toc = described_class.generate(doc, min_level: 2)

        expect(toc.min_level).to eq(2)
      end

      it 'sets max_level on generated TOC' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc, max_level: 4)

        expect(toc.max_level).to eq(4)
      end

      it 'sets numbered flag on generated TOC' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc, numbered: true)

        expect(toc.numbered).to be true
      end

      it 'defaults min_level to 1' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.min_level).to eq(1)
      end

      it 'defaults max_level to 6' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.max_level).to eq(6)
      end
    end

    describe 'edge cases' do
      it 'handles section with nil level' do
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          id: 's1',
          title: 'Section',
          level: nil,
          children: []
        )
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        # nil level should be treated as 1
        expect(toc.entries.length).to eq(1)
      end

      it 'handles document with mixed content' do
        section = create_section(id: 's1', title: 'Section', level: 1)
        paragraph = Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Text')
        doc = create_document(children: [paragraph, section])

        toc = described_class.generate(doc)

        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.title).to eq('Section')
      end

      it 'handles sections with missing id' do
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'No ID Section',
          level: 1,
          children: []
        )
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.id).to be_nil
      end

      it 'handles sections with missing title' do
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          id: 'no-title',
          level: 1,
          children: []
        )
        doc = create_document(children: [section])

        toc = described_class.generate(doc)

        expect(toc.entries.length).to eq(1)
        expect(toc.entries.first.title).to be_nil
      end
    end
  end

  describe 'DEFAULT_OPTIONS' do
    it 'defines default min_level as 1' do
      expect(described_class::DEFAULT_OPTIONS[:min_level]).to eq(1)
    end

    it 'defines default max_level as 6' do
      expect(described_class::DEFAULT_OPTIONS[:max_level]).to eq(6)
    end

    it 'defines default numbered as false' do
      expect(described_class::DEFAULT_OPTIONS[:numbered]).to be false
    end

    it 'defines default styled as false' do
      expect(described_class::DEFAULT_OPTIONS[:styled]).to be false
    end
  end
end
