# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::TocBuilder do
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      title: 'Test Document',
      children: [
        Coradoc::CoreModel::SectionElement.new(
          id: 'intro', title: 'Introduction', level: 1,
          children: [
            Coradoc::CoreModel::SectionElement.new(
              id: 'background', title: 'Background', level: 2
            )
          ]
        ),
        Coradoc::CoreModel::SectionElement.new(
          id: 'main', title: 'Main Content', level: 1,
          children: [
            Coradoc::CoreModel::SectionElement.new(
              id: 'subsection', title: 'Subsection', level: 2
            )
          ]
        ),
        Coradoc::CoreModel::SectionElement.new(
          id: 'conclusion', title: 'Conclusion', level: 1
        )
      ]
    )
  end

  describe '.from_options' do
    it 'builds a TocBuilder from renderer options hash' do
      builder = described_class.from_options(
        section_numbers: true, section_number_levels: 3, toc_levels: 2
      )
      toc = builder.build(document)

      expect(toc).to be_a(Coradoc::CoreModel::Toc)
      expect(toc.numbered).to be true
      expect(toc.entries[0].number).to eq('1')
    end

    it 'uses defaults when options are empty' do
      builder = described_class.from_options({})
      toc, = builder.build_with_numbers(document)

      expect(toc.numbered).to be false
      expect(toc.entries[0].number).to be_nil
    end

    it 'uses min of toclevels and sectnumlevels as max_level' do
      builder = described_class.from_options(toc_levels: 1, section_number_levels: 6)
      toc = builder.build(document)

      expect(toc.entries[0].children).to be_empty
    end
  end

  describe '#build' do
    it 'builds a Toc model with entries from the document tree' do
      toc = described_class.new(max_level: 3).build(document)

      expect(toc).to be_a(Coradoc::CoreModel::Toc)
      expect(toc.entries.length).to eq(3)
    end

    it 'assigns section numbers when numbered is true' do
      toc = described_class.new(max_level: 3, numbered: true, section_number_levels: 3).build(document)

      expect(toc.entries[0].number).to eq('1')
      expect(toc.entries[0].title).to eq('Introduction')
      expect(toc.entries[0].children[0].number).to eq('1.1')
      expect(toc.entries[0].children[0].title).to eq('Background')

      expect(toc.entries[1].number).to eq('2')
      expect(toc.entries[1].title).to eq('Main Content')
      expect(toc.entries[1].children[0].number).to eq('2.1')
      expect(toc.entries[1].children[0].title).to eq('Subsection')

      expect(toc.entries[2].number).to eq('3')
      expect(toc.entries[2].title).to eq('Conclusion')
    end

    it 'does not assign numbers when numbered is false' do
      toc, = described_class.new(max_level: 3, numbered: false).build_with_numbers(document)

      expect(toc.entries[0].number).to be_nil
    end

    it 'respects max_level to limit TOC depth' do
      toc = described_class.new(max_level: 1, numbered: true, section_number_levels: 3).build(document)

      expect(toc.entries.length).to eq(3)
      expect(toc.entries[0].children).to be_empty
    end

    it 'sets numbered on the Toc model' do
      toc = described_class.new(numbered: true).build(document)
      expect(toc.numbered).to be true
    end
  end

  describe '#build_with_numbers' do
    it 'returns a mapping of section IDs to number strings' do
      _, map = described_class.new(max_level: 3, section_number_levels: 3).build_with_numbers(document)

      expect(map['intro']).to eq('1')
      expect(map['background']).to eq('1.1')
      expect(map['main']).to eq('2')
      expect(map['subsection']).to eq('2.1')
      expect(map['conclusion']).to eq('3')
    end

    it 'excludes sections beyond section_number_levels' do
      deep_doc = Coradoc::CoreModel::DocumentElement.new(
        title: 'Deep',
        children: [
          Coradoc::CoreModel::SectionElement.new(
            id: 's1', title: 'S1', level: 1,
            children: [
              Coradoc::CoreModel::SectionElement.new(
                id: 's1-1', title: 'S1.1', level: 2,
                children: [
                  Coradoc::CoreModel::SectionElement.new(
                    id: 's1-1-1', title: 'S1.1.1', level: 3
                  )
                ]
              )
            ]
          )
        ]
      )

      _, map = described_class.new(max_level: 6, section_number_levels: 2).build_with_numbers(deep_doc)

      expect(map['s1']).to eq('1')
      expect(map['s1-1']).to eq('1.1')
      expect(map['s1-1-1']).to be_nil
    end
  end
end
