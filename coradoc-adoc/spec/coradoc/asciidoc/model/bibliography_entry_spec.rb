# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::BibliographyEntry do
  describe '.coerce_ref_text' do
    it 'returns empty string for nil' do
      expect(described_class.coerce_ref_text(nil)).to eq('')
    end

    it 'returns a plain string unchanged' do
      expect(described_class.coerce_ref_text('Smith 2023')).to eq('Smith 2023')
    end

    it 'concatenates an Array of strings' do
      expect(described_class.coerce_ref_text(%w[Smith 2023])).to eq('Smith2023')
    end

    it 'stringifies non-String scalars' do
      expect(described_class.coerce_ref_text(42)).to eq('42')
    end

    it 'recurses through nested arrays' do
      expect(described_class.coerce_ref_text(['a', ['b', 'c']])).to eq('abc')
    end
  end

  describe '.new' do
    it 'builds an entry with all fields' do
      entry = described_class.new(
        anchor_name: 'smith2023',
        document_id: 'ISO-1234',
        ref_text: 'Smith (2023)',
        line_break: "\n"
      )
      expect(entry.anchor_name).to eq('smith2023')
      expect(entry.document_id).to eq('ISO-1234')
      expect(entry.ref_text).to eq('Smith (2023)')
      expect(entry.line_break).to eq("\n")
    end

    it 'defaults line_break to empty string' do
      expect(described_class.new.line_break).to eq('')
    end
  end
end
