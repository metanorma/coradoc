# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Include do
  describe 'attribute defaults' do
    it 'defaults target to nil' do
      expect(described_class.new.target).to be_nil
    end

    it 'defaults options to an empty IncludeOptions' do
      expect(described_class.new.options).to be_a(Coradoc::CoreModel::IncludeOptions)
    end

    it 'defaults raw_options to empty string' do
      expect(described_class.new.raw_options).to eq('')
    end

    it 'defaults line_break to \n' do
      expect(described_class.new.line_break).to eq("\n")
    end
  end

  describe 'semantic_type' do
    it 'reports :include' do
      expect(described_class.semantic_type).to eq(:include)
    end
  end
end

RSpec.describe Coradoc::CoreModel::IncludeOptions do
  describe 'attribute defaults' do
    subject(:options) { described_class.new }

    it 'defaults tags to an empty array' do
      expect(options.tags).to eq([])
    end

    it 'defaults tags_wildcard to false' do
      expect(options.tags_wildcard).to eq(false)
    end

    it 'defaults tags_inverted to false' do
      expect(options.tags_inverted).to eq(false)
    end

    it 'defaults lines_spec to nil' do
      expect(options.lines_spec).to be_nil
    end

    it 'defaults leveloffset to nil' do
      expect(options.leveloffset).to be_nil
    end

    it 'defaults indent to nil' do
      expect(options.indent).to be_nil
    end

    it 'defaults file_encoding to nil' do
      expect(options.file_encoding).to be_nil
    end
  end

  describe '#tags?' do
    it 'returns false when no tags are set' do
      expect(described_class.new).not_to be_tags
    end

    it 'returns true when named tags are set' do
      expect(described_class.new(tags: ['body'])).to be_tags
    end

    it 'returns true when wildcard is set' do
      expect(described_class.new(tags_wildcard: true)).to be_tags
    end

    it 'returns true when inverted is set' do
      expect(described_class.new(tags_inverted: true)).to be_tags
    end
  end

  describe '#lines?' do
    it 'returns false when no lines_spec is set' do
      expect(described_class.new).not_to be_lines
    end

    it 'returns true when lines_spec is set' do
      expect(described_class.new(lines_spec: '1..2')).to be_lines
    end
  end

  describe '.from_hash' do
    it 'parses a single tag string into a one-element array' do
      options = described_class.from_hash('tags' => 'body')
      expect(options.tags).to eq(['body'])
    end

    it 'parses a semicolon-separated tag string into multiple tags' do
      options = described_class.from_hash('tags' => 'a;b;c')
      expect(options.tags).to eq(%w[a b c])
    end

    it 'recognizes tags=* as wildcard' do
      options = described_class.from_hash('tags' => '*')
      expect(options.tags_wildcard).to eq(true)
    end

    it 'recognizes tags=** as inverted' do
      options = described_class.from_hash('tags' => '**')
      expect(options.tags_inverted).to eq(true)
    end

    it 'parses a relative leveloffset string into IncludeLevelOffset' do
      options = described_class.from_hash('leveloffset' => '+2')
      expect(options.leveloffset.delta).to eq(2)
      expect(options.leveloffset.mode).to eq('relative')
    end

    it 'parses an absolute leveloffset string into IncludeLevelOffset' do
      options = described_class.from_hash('leveloffset' => '3')
      expect(options.leveloffset.delta).to eq(3)
      expect(options.leveloffset.mode).to eq('absolute')
    end

    it 'parses indent as an integer' do
      options = described_class.from_hash('indent' => '2')
      expect(options.indent).to eq(2)
    end
  end
end

RSpec.describe Coradoc::CoreModel::IncludeLevelOffset do
  describe '.parse' do
    it 'parses +N as relative positive' do
      offset = described_class.parse('+2')
      expect(offset.mode).to eq('relative')
      expect(offset.delta).to eq(2)
    end

    it 'parses -N as relative negative' do
      offset = described_class.parse('-1')
      expect(offset.mode).to eq('relative')
      expect(offset.delta).to eq(-1)
    end

    it 'parses a bare number as absolute' do
      offset = described_class.parse('3')
      expect(offset.mode).to eq('absolute')
      expect(offset.delta).to eq(3)
    end

    it 'returns nil for empty input' do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse('')).to be_nil
    end
  end

  describe '#apply' do
    it 'shifts by delta for relative mode' do
      offset = described_class.new(mode: 'relative', delta: 2)
      expect(offset.apply(1)).to eq(3)
    end

    it 'forces the level for absolute mode' do
      offset = described_class.new(mode: 'absolute', delta: 4)
      expect(offset.apply(1)).to eq(4)
    end
  end

  describe '#to_s' do
    it 'renders +N for relative positive' do
      expect(described_class.new(mode: 'relative', delta: 2).to_s).to eq('+2')
    end

    it 'renders -N for relative negative' do
      expect(described_class.new(mode: 'relative', delta: -1).to_s).to eq('-1')
    end

    it 'renders the bare number for absolute' do
      expect(described_class.new(mode: 'absolute', delta: 3).to_s).to eq('3')
    end
  end
end
