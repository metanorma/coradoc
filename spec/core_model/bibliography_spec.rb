# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Bibliography do
  describe '.new' do
    it 'creates an empty bibliography' do
      bib = described_class.new
      expect(bib.entries).to be_nil.or be_empty
    end

    it 'creates a bibliography with metadata' do
      bib = described_class.new(
        id: 'norm-refs',
        title: 'Normative references',
        level: 1
      )

      expect(bib.id).to eq('norm-refs')
      expect(bib.title).to eq('Normative references')
      expect(bib.level).to eq(1)
    end

    it 'creates a bibliography with entries' do
      entry = Coradoc::CoreModel::BibliographyEntry.new(
        anchor_name: 'ISO712',
        document_id: 'ISO 712',
        ref_text: 'Cereals and cereal products.'
      )
      bib = described_class.new(entries: [entry])

      expect(bib.entries.length).to eq(1)
      expect(bib.entries.first.anchor_name).to eq('ISO712')
    end
  end

  describe '#accept' do
    it 'accepts a visitor' do
      bib = described_class.new(title: 'References')
      collector = Coradoc::Visitor::Collector.new(described_class)
      bib.accept(collector)

      expect(collector.items).to include(bib)
    end
  end
end

RSpec.describe Coradoc::CoreModel::BibliographyEntry do
  describe '.new' do
    it 'creates an entry with all attributes' do
      entry = described_class.new(
        anchor_name: 'ISO712',
        document_id: 'ISO 712',
        ref_text: 'Cereals and cereal products.',
        url: 'https://example.com/iso712'
      )

      expect(entry.anchor_name).to eq('ISO712')
      expect(entry.document_id).to eq('ISO 712')
      expect(entry.ref_text).to eq('Cereals and cereal products.')
      expect(entry.url).to eq('https://example.com/iso712')
    end
  end

  describe '#display_text' do
    it 'combines document_id and ref_text' do
      entry = described_class.new(
        document_id: 'ISO 712',
        ref_text: 'Cereals and cereal products.'
      )

      expect(entry.display_text).to eq('ISO 712: Cereals and cereal products.')
    end

    it 'uses anchor_name when document_id is absent' do
      entry = described_class.new(
        anchor_name: 'ISO712',
        ref_text: 'Cereals and cereal products.'
      )

      expect(entry.display_text).to eq('ISO712: Cereals and cereal products.')
    end

    it 'returns ref_text alone when no label available' do
      entry = described_class.new(ref_text: 'Some reference text')

      expect(entry.display_text).to eq('Some reference text')
    end
  end
end
