# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Block::Quote do
  describe '.new' do
    it 'creates a quote block with default delimiter' do
      quote = described_class.new

      expect(quote.delimiter_char).to eq('_')
      expect(quote.delimiter_len).to eq(4)
    end

    it 'creates a quote block with lines' do
      quote = described_class.new(lines: ['Quote line 1', 'Quote line 2'])

      expect(quote.lines).to contain_exactly('Quote line 1', 'Quote line 2')
    end
  end

  describe '#delimiter_char' do
    it 'can be customized' do
      quote = described_class.new
      quote.delimiter_char = '*'

      expect(quote.delimiter_char).to eq('*')
    end
  end

  describe '#delimiter_len' do
    it 'can be customized' do
      quote = described_class.new
      quote.delimiter_len = 6

      expect(quote.delimiter_len).to eq(6)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      quote = described_class.new

      expect(quote).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end

    it 'inherits from Base' do
      quote = described_class.new

      expect(quote).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      quote = described_class.new(lines: ['Test quote'])

      adoc = quote.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('____')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Block::Example do
  describe '.new' do
    it 'creates an example block with default delimiter' do
      example = described_class.new

      expect(example.delimiter_char).to eq('=')
      expect(example.delimiter_len).to eq(4)
    end

    it 'creates an example block with lines' do
      example = described_class.new(lines: ['Example line 1', 'Example line 2'])

      expect(example.lines).to contain_exactly('Example line 1', 'Example line 2')
    end
  end

  describe '#delimiter_char' do
    it 'can be customized' do
      example = described_class.new
      example.delimiter_char = '-'

      expect(example.delimiter_char).to eq('-')
    end
  end

  describe '#delimiter_len' do
    it 'can be customized' do
      example = described_class.new
      example.delimiter_len = 6

      expect(example.delimiter_len).to eq(6)
    end
  end

  describe 'inheritance' do
    it 'inherits from Block::Core' do
      example = described_class.new

      expect(example).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
    end

    it 'inherits from Base' do
      example = described_class.new

      expect(example).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      example = described_class.new(lines: ['Test example'])

      adoc = example.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('====')
    end
  end
end
