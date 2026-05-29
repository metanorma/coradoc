# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/bibliography_drop'
require 'coradoc/html/drop/bibliography_entry_drop'

RSpec.describe Coradoc::Html::Drop::BibliographyDrop do
  let(:entry) do
    CoreModel::BibliographyEntry.new(
      anchor_name: 'ISO712',
      document_id: 'ISO 712',
      ref_text: 'Cereals.'
    )
  end
  let(:model) { CoreModel::Bibliography.new(id: 'bib', title: 'References', level: 1, entries: [entry]) }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#id' do
    it 'returns the bibliography id' do
      expect(drop.id).to eq('bib')
    end
  end

  describe '#title' do
    it 'returns escaped title' do
      expect(drop.title).to eq('References')
    end

    it 'returns nil for empty title' do
      bib = CoreModel::Bibliography.new(level: 1)
      expect(described_class.new(bib).title).to be_nil
    end
  end

  describe '#entries' do
    it 'returns an array of BibliographyEntryDrop' do
      entries = drop.entries
      expect(entries).to be_an(Array)
      expect(entries.first).to be_a(Coradoc::Html::Drop::BibliographyEntryDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::BibliographyEntryDrop do
  let(:model) do
    CoreModel::BibliographyEntry.new(
      anchor_name: 'ISO712',
      document_id: 'ISO 712',
      ref_text: 'Cereals and cereal products.'
    )
  end
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#anchor_name' do
    it 'returns the anchor name' do
      expect(drop.anchor_name).to eq('ISO712')
    end
  end

  describe '#document_id' do
    it 'returns escaped document id' do
      expect(drop.document_id).to eq('ISO 712')
    end
  end

  describe '#ref_text' do
    it 'returns escaped ref text' do
      expect(drop.ref_text).to eq('Cereals and cereal products.')
    end
  end
end
