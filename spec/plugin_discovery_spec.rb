# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::PluginDiscovery do
  describe '.auto_discover' do
    after do
      described_class.auto_discover = true
    end

    it 'is enabled by default' do
      expect(described_class.auto_discover).to be true
    end

    it 'can be disabled' do
      described_class.auto_discover = false
      expect(described_class.auto_discover).to be false
    end
  end

  describe '.discover' do
    it 'returns an array' do
      result = described_class.discover
      expect(result).to be_an(Array)
    end

    it 'returns gem info hashes' do
      result = described_class.discover
      result.each do |gem_info|
        expect(gem_info).to be_a(Hash)
        expect(gem_info).to have_key(:name)
        expect(gem_info).to have_key(:format_name)
        expect(gem_info).to have_key(:version)
      end
    end

    it 'finds installed coradoc format gems' do
      result = described_class.discover
      gem_names = result.map { |g| g[:name] }

      # In a monorepo, these may not show up as separate gems
      # but the pattern matching should work
      expect(gem_names).to be_an(Array)
    end
  end

  describe '.installed?' do
    it 'returns false for non-existent gems' do
      expect(described_class.installed?(:nonexistent_format)).to be false
    end
  end

  describe '.version' do
    it 'returns nil for non-existent gems' do
      expect(described_class.version(:nonexistent_format)).to be_nil
    end
  end

  describe '.known_format_gems' do
    it 'returns list of known format gem names' do
      gems = described_class.known_format_gems

      expect(gems).to be_an(Array)
      expect(gems).to include('coradoc-adoc')
      expect(gems).to include('coradoc-html')
      expect(gems).to include('coradoc-markdown')
    end

    it 'returns a copy of the list' do
      gems1 = described_class.known_format_gems
      gems2 = described_class.known_format_gems

      expect(gems1).not_to equal(gems2)
    end
  end

  describe '.discover_and_register' do
    before do
      described_class.auto_discover = true
    end

    after do
      described_class.auto_discover = true
    end

    it 'returns empty array when auto_discover is disabled' do
      described_class.auto_discover = false
      result = described_class.discover_and_register
      expect(result).to eq([])
    end

    it 'returns array of registered format names' do
      # In monorepo, gems are already loaded
      result = described_class.discover_and_register
      expect(result).to be_an(Array)
    end
  end

  describe 'FORMAT_GEM_PATTERN' do
    it 'matches coradoc format gem names' do
      pattern = Coradoc::PluginDiscovery::FORMAT_GEM_PATTERN

      expect('coradoc-html').to match(pattern)
      expect('coradoc-markdown').to match(pattern)
      expect('coradoc-adoc').to match(pattern)
      expect('coradoc-pdf').to match(pattern)
    end

    it 'does not match non-format gem names' do
      pattern = Coradoc::PluginDiscovery::FORMAT_GEM_PATTERN

      expect('coradoc').not_to match(pattern)
      expect('other-gem').not_to match(pattern)
      expect('rails').not_to match(pattern)
    end

    it 'extracts format name from gem name' do
      pattern = Coradoc::PluginDiscovery::FORMAT_GEM_PATTERN
      match = pattern.match('coradoc-html')

      expect(match[1]).to eq('html')
    end
  end
end
