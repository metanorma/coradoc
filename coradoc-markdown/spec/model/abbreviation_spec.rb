# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Abbreviation do
  describe '.new' do
    it 'creates an abbreviation with term and definition' do
      abbr = described_class.new(term: 'HTML', definition: 'HyperText Markup Language')

      expect(abbr.term).to eq('HTML')
      expect(abbr.definition).to eq('HyperText Markup Language')
    end
  end
end

RSpec.describe 'Abbreviation Parsing' do
  let(:parser) { Coradoc::Markdown::Parser::BlockParser.new }

  describe 'abbreviation definition' do
    it 'parses a simple abbreviation definition' do
      result = parser.parse("*[HTML]: HyperText Markup Language\n")

      expect(result).to be_an(Array)
      expect(result.first).to have_key(:abbr_term)
      expect(result.first).to have_key(:abbr_def)
    end

    it 'parses abbreviation with spaces in term' do
      result = parser.parse("*[foo bar]: baz\n")

      expect(result.first[:abbr_term].to_s).to eq('foo bar')
    end
  end

  describe 'abbreviation model transformation' do
    it 'transforms AST to Abbreviation model' do
      doc = Coradoc::Markdown.parse("Some text\n\n*[HTML]: HyperText Markup Language\n")

      expect(doc.blocks).to be_an(Array)
      expect(doc.blocks.length).to eq(2)
      expect(doc.blocks.first).to be_a(Coradoc::Markdown::Paragraph)
      expect(doc.blocks.last).to be_a(Coradoc::Markdown::Abbreviation)
      expect(doc.blocks.last.term).to eq('HTML')
      expect(doc.blocks.last.definition).to eq('HyperText Markup Language')
    end

    it 'handles empty definition' do
      doc = Coradoc::Markdown.parse("*[empty]: \n")

      expect(doc.blocks.first).to be_a(Coradoc::Markdown::Abbreviation)
      expect(doc.blocks.first.term).to eq('empty')
      # Empty definitions may be parsed as empty array or empty string
      expect(['', '[]']).to include(doc.blocks.first.definition)
    end
  end
end
