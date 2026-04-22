# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::ParserUtil::IalParser do
  describe '.tokenize' do
    it 'parses class tokens' do
      tokens = described_class.tokenize('.highlight .warning')
      expect(tokens).to eq([
                             { type: :class, value: 'highlight' },
                             { type: :class, value: 'warning' }
                           ])
    end

    it 'parses id tokens' do
      tokens = described_class.tokenize('#introduction')
      expect(tokens).to eq([
                             { type: :id, value: 'introduction' }
                           ])
    end

    it 'parses attribute tokens with double quotes' do
      tokens = described_class.tokenize('data-value="hello"')
      expect(tokens).to eq([
                             { type: :attribute, key: 'data-value', value: 'hello' }
                           ])
    end

    it 'parses attribute tokens with single quotes' do
      tokens = described_class.tokenize("lang='ruby'")
      expect(tokens).to eq([
                             { type: :attribute, key: 'lang', value: 'ruby' }
                           ])
    end

    it 'parses attribute tokens with unquoted values' do
      tokens = described_class.tokenize('enabled=true')
      expect(tokens).to eq([
                             { type: :attribute, key: 'enabled', value: 'true' }
                           ])
    end

    it 'parses mixed tokens' do
      tokens = described_class.tokenize('.highlight #main data-id="123"')
      expect(tokens).to eq([
                             { type: :class, value: 'highlight' },
                             { type: :id, value: 'main' },
                             { type: :attribute, key: 'data-id', value: '123' }
                           ])
    end

    it 'handles escaped quotes in values' do
      tokens = described_class.tokenize('title="He said \\"hello\\""')
      expect(tokens).to eq([
                             { type: :attribute, key: 'title', value: 'He said "hello"' }
                           ])
    end

    it 'handles class with dash prefix' do
      tokens = described_class.tokenize('.-hidden')
      expect(tokens).to eq([
                             { type: :class, value: '-hidden' }
                           ])
    end

    it 'returns empty array for nil content' do
      expect(described_class.tokenize(nil)).to eq([])
    end

    it 'returns empty array for empty content' do
      expect(described_class.tokenize('')).to eq([])
    end
  end

  describe '.parse_to_hash' do
    it 'returns empty result for nil content' do
      result = described_class.parse_to_hash(nil)
      expect(result).to eq({ id: nil, classes: [], attributes: {} })
    end

    it 'returns empty result for empty content' do
      result = described_class.parse_to_hash('')
      expect(result).to eq({ id: nil, classes: [], attributes: {} })
    end

    it 'parses single class' do
      result = described_class.parse_to_hash('.highlight')
      expect(result).to eq({ id: nil, classes: ['highlight'], attributes: {} })
    end

    it 'parses multiple classes' do
      result = described_class.parse_to_hash('.highlight .warning .alert')
      expect(result).to eq({ id: nil, classes: %w[highlight warning alert], attributes: {} })
    end

    it 'parses id' do
      result = described_class.parse_to_hash('#main-section')
      expect(result).to eq({ id: 'main-section', classes: [], attributes: {} })
    end

    it 'parses attributes' do
      result = described_class.parse_to_hash('data-id="123" lang="en"')
      expect(result).to eq({ id: nil, classes: [], attributes: { 'data-id' => '123', 'lang' => 'en' } })
    end

    it 'parses complex IAL' do
      result = described_class.parse_to_hash('.note .warning #security data-role="alert"')
      expect(result).to eq({
                             id: 'security',
                             classes: %w[note warning],
                             attributes: { 'data-role' => 'alert' }
                           })
    end

    it 'handles whitespace gracefully' do
      result = described_class.parse_to_hash('  .highlight   #main  ')
      expect(result).to eq({ id: 'main', classes: ['highlight'], attributes: {} })
    end
  end
end
