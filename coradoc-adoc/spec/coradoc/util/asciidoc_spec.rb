# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Util::AsciiDoc do
  describe '.escape_characters' do
    it 'returns empty string for nil input' do
      expect(described_class.escape_characters(nil)).to eq('')
    end

    it 'returns empty string for empty input' do
      expect(described_class.escape_characters('')).to eq('')
    end

    it 'returns content unchanged when no escape_chars specified' do
      expect(described_class.escape_characters('hello world')).to eq('hello world')
    end

    it 'escapes asterisks' do
      result = described_class.escape_characters('2 * 3 = 6', escape_chars: ['*'])
      expect(result).to eq('2 \\* 3 = 6')
    end

    it 'escapes underscores' do
      result = described_class.escape_characters('hello_world', escape_chars: ['_'])
      expect(result).to eq('hello\\_world')
    end

    it 'escapes multiple occurrences' do
      result = described_class.escape_characters('*a* and *b*', escape_chars: ['*'])
      expect(result).to eq('\\*a\\* and \\*b\\*')
    end

    it 'escapes multiple different characters' do
      result = described_class.escape_characters('*bold* and _italic_', escape_chars: %w[* _])
      expect(result).to eq('\\*bold\\* and \\_italic\\_')
    end

    it 'does not double-escape already escaped characters' do
      result = described_class.escape_characters('already \\* escaped', escape_chars: ['*'])
      expect(result).to eq('already \\* escaped')
    end
  end

  describe '.unescape_characters' do
    it 'returns empty string for nil input' do
      expect(described_class.unescape_characters(nil)).to eq('')
    end

    it 'returns content unchanged when no escape_chars specified' do
      expect(described_class.unescape_characters('hello world')).to eq('hello world')
    end

    it 'unescapes asterisks' do
      result = described_class.unescape_characters('2 \\* 3 = 6', escape_chars: ['*'])
      expect(result).to eq('2 * 3 = 6')
    end

    it 'is inverse of escape_characters' do
      original = '2 * 3 = 6'
      escaped = described_class.escape_characters(original, escape_chars: ['*'])
      unescaped = described_class.unescape_characters(escaped, escape_chars: ['*'])
      expect(unescaped).to eq(original)
    end
  end
end
