# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Term do
  describe '.new' do
    it 'creates a term with all attributes' do
      term = described_class.new(
        term: 'API',
        type: 'acronym',
        lang: 'en'
      )

      expect(term.term).to eq('API')
      expect(term.type).to eq('acronym')
      expect(term.lang).to eq('en')
    end

    it 'creates a term with default language' do
      term = described_class.new(term: 'XML', type: 'acronym')

      expect(term.term).to eq('XML')
      expect(term.type).to eq('acronym')
      expect(term.lang).to eq('en')
    end

    it 'creates a term with custom language' do
      term = described_class.new(term: 'Bonjour', type: 'preferred', lang: 'fr')

      expect(term.lang).to eq('fr')
    end
  end

  describe '#term' do
    it 'can be set and retrieved' do
      term = described_class.new
      term.term = 'JSON'

      expect(term.term).to eq('JSON')
    end
  end

  describe '#type' do
    it 'can be set and retrieved' do
      term = described_class.new
      term.type = 'symbol'

      expect(term.type).to eq('symbol')
    end
  end

  describe '#lang' do
    it 'can be overridden' do
      term = described_class.new
      term.lang = 'de'

      expect(term.lang).to eq('de')
    end
  end

  describe '#line_break' do
    it 'has default value' do
      term = described_class.new

      expect(term.line_break).to eq('')
    end

    it 'can be customized' do
      term = described_class.new
      term.line_break = "\n"

      expect(term.line_break).to eq("\n")
    end
  end

  describe '#validate' do
    it 'returns errors for nil term' do
      term = described_class.new(type: 'acronym')

      errors = term.validate
      expect(errors).not_to be_empty
      expect(errors.any? { |e| e.message.include?('Term cannot be nil or empty') }).to be true
    end

    it 'returns errors for empty term' do
      term = described_class.new(term: '', type: 'acronym')

      errors = term.validate
      expect(errors.any? { |e| e.message.include?('Term cannot be nil or empty') }).to be true
    end

    it 'returns errors for nil type' do
      term = described_class.new(term: 'API')

      errors = term.validate
      expect(errors.any? { |e| e.message.include?('Type cannot be nil or empty') }).to be true
    end

    it 'returns no errors for valid term' do
      term = described_class.new(term: 'API', type: 'acronym')

      errors = term.validate
      expect(errors).to be_empty
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      term = described_class.new

      expect(term).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      term = described_class.new(term: 'HTML', type: 'acronym')

      adoc = term.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end
