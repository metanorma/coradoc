# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Parser::Cache do
  describe '.new' do
    it 'creates a cache with default max size' do
      cache = described_class.new
      expect(cache.stats[:max_size]).to eq(described_class::DEFAULT_MAX_SIZE)
    end

    it 'creates a cache with custom max size' do
      cache = described_class.new(max_size: 10)
      expect(cache.stats[:max_size]).to eq(10)
    end
  end

  describe '#fetch_or_parse' do
    let(:cache) { described_class.new }

    it 'yields block on cache miss' do
      content = 'test content'
      block_called = false

      result = cache.fetch_or_parse(content) do
        block_called = true
        :parsed_result
      end

      expect(block_called).to be true
      expect(result).to eq(:parsed_result)
    end

    it 'returns cached result on cache hit' do
      content = 'test content'
      call_count = 0

      2.times do
        cache.fetch_or_parse(content) do
          call_count += 1
          :parsed_result
        end
      end

      expect(call_count).to eq(1)
    end

    it 'caches different content separately' do
      call_count = 0

      cache.fetch_or_parse('content 1') do
        call_count += 1
        :result1
      end
      cache.fetch_or_parse('content 2') do
        call_count += 1
        :result2
      end

      expect(call_count).to eq(2)
    end

    it 'handles identical content' do
      content = 'identical'
      results = []

      3.times do
        results << cache.fetch_or_parse(content) { :parsed }
      end

      expect(results).to eq(%i[parsed parsed parsed])
    end
  end

  describe '#cached?' do
    let(:cache) { described_class.new }

    it 'returns false for uncached content' do
      expect(cache.cached?('uncached')).to be false
    end

    it 'returns true for cached content' do
      content = 'cached content'
      cache.fetch_or_parse(content) { :result }

      expect(cache.cached?(content)).to be true
    end
  end

  describe '#size' do
    let(:cache) { described_class.new }

    it 'returns 0 for empty cache' do
      expect(cache.size).to eq(0)
    end

    it 'returns correct size after caching' do
      cache.fetch_or_parse('content 1') { :r1 }
      cache.fetch_or_parse('content 2') { :r2 }

      expect(cache.size).to eq(2)
    end
  end

  describe '#clear' do
    let(:cache) { described_class.new }

    it 'clears all cached entries' do
      cache.fetch_or_parse('content 1') { :r1 }
      cache.fetch_or_parse('content 2') { :r2 }

      cache.clear

      expect(cache.size).to eq(0)
    end
  end

  describe 'LRU eviction' do
    let(:cache) { described_class.new(max_size: 2) }

    it 'evicts oldest entry when at capacity' do
      cache.fetch_or_parse('content 1') { :r1 }
      cache.fetch_or_parse('content 2') { :r2 }
      cache.fetch_or_parse('content 3') { :r3 } # Should evict content 1

      expect(cache.cached?('content 1')).to be false
      expect(cache.cached?('content 2')).to be true
      expect(cache.cached?('content 3')).to be true
    end

    it 'updates access order on cache hit' do
      cache.fetch_or_parse('content 1') { :r1 }
      cache.fetch_or_parse('content 2') { :r2 }
      cache.fetch_or_parse('content 1') { :r1 } # Access content 1 again
      cache.fetch_or_parse('content 3') { :r3 } # Should evict content 2

      expect(cache.cached?('content 1')).to be true
      expect(cache.cached?('content 2')).to be false
      expect(cache.cached?('content 3')).to be true
    end
  end

  describe '.global' do
    after do
      described_class.global = nil
    end

    it 'returns nil by default' do
      expect(described_class.global).to be_nil
    end

    it 'can be set' do
      cache = described_class.new
      described_class.global = cache
      expect(described_class.global).to eq(cache)
    end
  end

  describe '.with_global' do
    it 'sets global cache temporarily' do
      described_class.with_global do |cache|
        expect(described_class.global).to eq(cache)
      end

      expect(described_class.global).to be_nil
    end

    it 'restores previous global cache' do
      original = described_class.new
      described_class.global = original

      described_class.with_global do |cache|
        expect(described_class.global).to eq(cache)
      end

      expect(described_class.global).to eq(original)
    end
  end

  describe '.clear_global!' do
    it 'clears the global cache' do
      described_class.with_global do |cache|
        cache.fetch_or_parse('content') { :result }
        expect(cache.size).to eq(1)

        described_class.clear_global!
        expect(cache.size).to eq(0)
      end
    end
  end

  describe '#stats' do
    let(:cache) { described_class.new(max_size: 5) }

    it 'returns cache statistics' do
      cache.fetch_or_parse('content 1') { :r1 }
      cache.fetch_or_parse('content 2') { :r2 }

      stats = cache.stats

      expect(stats[:size]).to eq(2)
      expect(stats[:max_size]).to eq(5)
      expect(stats[:keys].length).to eq(2)
    end
  end

  describe 'thread safety' do
    let(:cache) { described_class.new(max_size: 10) }

    it 'handles concurrent access' do
      threads = Array.new(10) do |i|
        Thread.new do
          10.times do |j|
            cache.fetch_or_parse("content #{i}-#{j}") { :result }
          end
        end
      end

      threads.each(&:join)

      expect(cache.size).to be <= 10
    end
  end
end
