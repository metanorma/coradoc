# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::BibliographyEntry do
  describe '#display_text' do
    it 'returns "label: ref_text" when document_id is present' do
      entry = described_class.new(document_id: 'ISO 712', ref_text: 'Cereals and cereal products.')
      expect(entry.display_text).to eq('ISO 712: Cereals and cereal products.')
    end

    it 'uses anchor_name as label when document_id is absent' do
      entry = described_class.new(anchor_name: 'ISO712', ref_text: 'Cereals.')
      expect(entry.display_text).to eq('ISO712: Cereals.')
    end

    it 'prefers document_id over anchor_name' do
      entry = described_class.new(
        anchor_name: 'ISO712',
        document_id: 'ISO 712',
        ref_text: 'Cereals.'
      )
      expect(entry.display_text).to eq('ISO 712: Cereals.')
    end

    it 'returns ref_text alone when no label is available' do
      entry = described_class.new(ref_text: 'Some reference text.')
      expect(entry.display_text).to eq('Some reference text.')
    end

    it 'returns empty string when all fields are nil' do
      entry = described_class.new
      expect(entry.display_text).to eq('')
    end
  end
end
