# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Term do
  describe '.new' do
    it 'creates a simple term' do
      term = described_class.new(
        text: 'API',
        type: 'acronym',
        definition: 'Application Programming Interface'
      )

      expect(term.text).to eq('API')
      expect(term.type).to eq('acronym')
      expect(term.definition).to eq('Application Programming Interface')
    end

    it 'creates a term with language' do
      term = described_class.new(
        text: 'ordinateur',
        type: 'preferred',
        lang: 'fr',
        definition: 'Machine electronique'
      )

      expect(term.lang).to eq('fr')
    end

    it "defaults language to 'en'" do
      term = described_class.new(text: 'computer')

      expect(term.lang).to eq('en')
    end

    it 'creates a deprecated term' do
      term = described_class.new(
        text: 'old_term',
        type: 'deprecated',
        definition: "Use 'new_term' instead"
      )

      expect(term.type).to eq('deprecated')
    end
  end

  describe '#semantically_equivalent?' do
    let(:term1) do
      described_class.new(
        text: 'API',
        type: 'acronym',
        lang: 'en',
        definition: 'Application Programming Interface'
      )
    end

    let(:term2) do
      described_class.new(
        text: 'API',
        type: 'acronym',
        lang: 'en',
        definition: 'Application Programming Interface'
      )
    end

    let(:different_text) do
      described_class.new(
        text: 'REST',
        type: 'acronym',
        lang: 'en',
        definition: 'Application Programming Interface'
      )
    end

    let(:different_type) do
      described_class.new(
        text: 'API',
        type: 'preferred',
        lang: 'en',
        definition: 'Application Programming Interface'
      )
    end

    let(:different_lang) do
      described_class.new(
        text: 'API',
        type: 'acronym',
        lang: 'fr',
        definition: 'Application Programming Interface'
      )
    end

    it 'returns true for identical terms' do
      expect(term1.semantically_equivalent?(term2)).to be true
    end

    it 'returns false for terms with different text' do
      expect(term1.semantically_equivalent?(different_text)).to be false
    end

    it 'returns false for terms with different type' do
      expect(term1.semantically_equivalent?(different_type)).to be false
    end

    it 'returns false for terms with different language' do
      expect(term1.semantically_equivalent?(different_lang)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
