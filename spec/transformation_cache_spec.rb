# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::TransformationCache do
  describe Coradoc::TransformationCache::Entry do
    let(:value) { 'test value' }
    let(:content_hash) { 'abc123' }
    let(:entry) { described_class.new(value, content_hash) }

    describe '#initialize' do
      it 'stores value and metadata' do
        expect(entry.value).to eq(value)
        expect(entry.content_hash).to eq(content_hash)
        expect(entry.created_at).to be_a(Time)
        expect(entry.size).to be_an(Integer)
      end
    end

    describe '#expired?' do
      it 'returns false for zero TTL' do
        expect(entry.expired?(0)).to be false
      end

      it 'returns false for fresh entries' do
        expect(entry.expired?(3600)).to be false
      end

      it 'returns true for old entries' do
        # Create an entry with old timestamp
        old_entry = described_class.new(value, content_hash)
        # Manually set created_at to be 2 hours ago
        old_entry.instance_variable_set(:@created_at, Time.now - 7200)
        expect(old_entry.expired?(3600)).to be true
      end
    end

    describe '#matches?' do
      it 'returns true for matching hash' do
        expect(entry.matches?(content_hash)).to be true
      end

      it 'returns false for different hash' do
        expect(entry.matches?('different')).to be false
      end
    end
  end

  describe Coradoc::TransformationCache::MemoryBackend do
    let(:backend) { described_class.new(max_size: 5, ttl: 0) }
    let(:entry) { Coradoc::TransformationCache::Entry.new('value', 'hash') }

    describe '#initialize' do
      it 'sets max size and ttl' do
        expect(backend.max_size).to eq(5)
        expect(backend.ttl).to eq(0)
      end
    end

    describe '#get and #set' do
      it 'stores and retrieves entries' do
        backend.set('key1', entry)
        expect(backend.get('key1')).to eq(entry)
      end

      it 'returns nil for missing keys' do
        expect(backend.get('missing')).to be_nil
      end
    end

    describe '#delete' do
      it 'deletes entries' do
        backend.set('key1', entry)
        expect(backend.delete('key1')).to be true
        expect(backend.get('key1')).to be_nil
      end

      it 'returns false for missing keys' do
        expect(backend.delete('missing')).to be false
      end
    end

    describe '#clear' do
      it 'clears all entries' do
        backend.set('key1', entry)
        backend.set('key2', entry)
        backend.clear
        expect(backend.get('key1')).to be_nil
        expect(backend.get('key2')).to be_nil
      end
    end

    describe '#stats' do
      it 'returns statistics' do
        backend.set('key1', entry)
        stats = backend.stats

        expect(stats[:entries]).to eq(1)
        expect(stats[:max_size]).to eq(5)
        expect(stats[:total_bytes]).to be >= 0
      end
    end

    describe '#key?' do
      it 'returns true for existing keys' do
        backend.set('key1', entry)
        expect(backend.key?('key1')).to be true
      end

      it 'returns false for missing keys' do
        expect(backend.key?('missing')).to be false
      end
    end

    describe 'LRU eviction' do
      it 'evicts least recently used entries' do
        6.times do |i|
          backend.set("key#{i}", entry)
        end

        # First key should be evicted
        expect(backend.get('key0')).to be_nil
        expect(backend.get('key5')).to eq(entry)
      end

      it 'updates access order on get' do
        5.times do |i|
          backend.set("key#{i}", entry)
        end

        # Access key0 to make it recently used
        backend.get('key0')

        # Add another entry
        backend.set('key6', entry)

        # key1 should be evicted (LRU), not key0
        expect(backend.get('key0')).to eq(entry)
        expect(backend.get('key1')).to be_nil
      end
    end

    describe 'TTL expiry' do
      let(:backend_with_ttl) { described_class.new(max_size: 5, ttl: 1) }

      it 'expires old entries' do
        backend_with_ttl.set('key1', entry)
        sleep(1.1)
        expect(backend_with_ttl.get('key1')).to be_nil
      end
    end
  end

  describe Coradoc::TransformationCache::FileBackend do
    let(:cache_dir) { Dir.mktmpdir('coradoc_cache') }
    let(:backend) { described_class.new(cache_dir: cache_dir, max_bytes: 1024 * 1024) }
    let(:entry) { Coradoc::TransformationCache::Entry.new('value', 'hash') }

    after do
      FileUtils.remove_entry(cache_dir) if Dir.exist?(cache_dir)
    end

    describe '#initialize' do
      it 'creates cache directory' do
        expect(Dir.exist?(cache_dir)).to be true
      end
    end

    describe '#get and #set' do
      it 'stores and retrieves entries' do
        backend.set('key1', entry)
        retrieved = backend.get('key1')
        expect(retrieved.value).to eq('value')
        expect(retrieved.content_hash).to eq('hash')
      end

      it 'returns nil for missing keys' do
        expect(backend.get('missing')).to be_nil
      end
    end

    describe '#delete' do
      it 'deletes entries' do
        backend.set('key1', entry)
        backend.delete('key1')
        expect(backend.get('key1')).to be_nil
      end
    end

    describe '#clear' do
      it 'clears all entries' do
        backend.set('key1', entry)
        backend.set('key2', entry)
        backend.clear
        expect(backend.get('key1')).to be_nil
        expect(backend.get('key2')).to be_nil
      end
    end

    describe '#stats' do
      it 'returns statistics' do
        backend.set('key1', entry)
        stats = backend.stats

        expect(stats[:entries]).to eq(1)
        expect(stats[:max_bytes]).to eq(1024 * 1024)
      end
    end
  end

  describe Coradoc::TransformationCache::KeyGenerator do
    describe '.generate' do
      it 'generates consistent keys for same input' do
        key1 = described_class.generate('content', from: :asciidoc, to: :html)
        key2 = described_class.generate('content', from: :asciidoc, to: :html)
        expect(key1).to eq(key2)
      end

      it 'generates different keys for different content' do
        key1 = described_class.generate('content1', from: :asciidoc)
        key2 = described_class.generate('content2', from: :asciidoc)
        expect(key1).not_to eq(key2)
      end

      it 'generates different keys for different options' do
        key1 = described_class.generate('content', from: :asciidoc, to: :html)
        key2 = described_class.generate('content', from: :markdown, to: :html)
        expect(key1).not_to eq(key2)
      end
    end

    describe '.content_hash' do
      it 'hashes strings' do
        hash = described_class.content_hash('test content')
        expect(hash).to be_a(String)
        expect(hash.length).to eq(64) # SHA256 hex length
      end

      it 'hashes arrays' do
        hash = described_class.content_hash(%w[a b c])
        expect(hash).to be_a(String)
      end

      it 'hashes hashes' do
        hash = described_class.content_hash({ key: 'value' })
        expect(hash).to be_a(String)
      end

      it 'produces consistent hashes' do
        hash1 = described_class.content_hash('same')
        hash2 = described_class.content_hash('same')
        expect(hash1).to eq(hash2)
      end
    end
  end

  describe 'module methods' do
    before do
      described_class.cache.clear
      # Ensure caching is enabled for tests
      allow(Coradoc.config.cache).to receive(:enabled).and_return(true)
    end

    describe '.cache' do
      it 'returns a cache backend' do
        expect(described_class.cache).to respond_to(:get)
        expect(described_class.cache).to respond_to(:set)
      end
    end

    describe '.fetch' do
      it 'caches computed values' do
        call_count = 0
        result = described_class.fetch('content', format: :asciidoc) do
          call_count += 1
          'computed'
        end

        expect(result).to eq('computed')
        expect(call_count).to eq(1)

        # Second call should use cache
        result2 = described_class.fetch('content', format: :asciidoc) do
          call_count += 1
          'computed again'
        end

        expect(result2).to eq('computed')
        expect(call_count).to eq(1) # Block not called again
      end

      it 'recomputes when content changes' do
        call_count = 0

        described_class.fetch('content1', format: :asciidoc) do
          call_count += 1
          'result1'
        end

        described_class.fetch('content2', format: :asciidoc) do
          call_count += 1
          'result2'
        end

        expect(call_count).to eq(2)
      end

      context 'when caching is disabled' do
        before do
          allow(Coradoc.config.cache).to receive(:enabled).and_return(false)
        end

        it 'always computes' do
          call_count = 0

          2.times do
            described_class.fetch('content', format: :asciidoc) do
              call_count += 1
              'computed'
            end
          end

          expect(call_count).to eq(2)
        end
      end
    end

    describe '.clear' do
      it 'clears the cache' do
        described_class.fetch('content', format: :asciidoc) { 'value' }
        described_class.clear

        call_count = 0
        described_class.fetch('content', format: :asciidoc) do
          call_count += 1
          'value'
        end

        expect(call_count).to eq(1)
      end
    end

    describe '.stats' do
      it 'returns cache statistics' do
        described_class.fetch('content', format: :asciidoc) { 'value' }
        stats = described_class.stats

        expect(stats).to have_key(:entries)
        expect(stats).to have_key(:max_size)
      end
    end

    describe '.create_file_cache' do
      it 'creates a file cache backend' do
        cache_dir = Dir.mktmpdir('coradoc_test')
        begin
          cache = described_class.create_file_cache(cache_dir)
          expect(cache).to be_a(Coradoc::TransformationCache::FileBackend)
        ensure
          FileUtils.remove_entry(cache_dir)
        end
      end
    end
  end
end
