# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Streaming do
  describe Coradoc::Streaming::Configuration do
    describe '#initialize' do
      it 'sets default values' do
        config = described_class.new
        expect(config.default_chunk_size).to eq(100)
        expect(config.max_memory).to eq(100 * 1024 * 1024)
        expect(config.monitor_memory).to be true
      end
    end
  end

  describe Coradoc::Streaming::Progress do
    describe '#initialize' do
      it 'creates progress with defaults' do
        progress = described_class.new
        expect(progress.total).to be_nil
        expect(progress.processed).to eq(0)
        expect(progress.errors).to eq([])
      end

      it 'creates progress with total' do
        progress = described_class.new(total: 100)
        expect(progress.total).to eq(100)
      end
    end

    describe '#increment' do
      it 'increments processed count' do
        progress = described_class.new
        progress.increment
        expect(progress.processed).to eq(1)

        progress.increment(5)
        expect(progress.processed).to eq(6)
      end
    end

    describe '#add_error' do
      it 'records errors' do
        progress = described_class.new
        progress.add_error('Error 1')
        error2 = RuntimeError.new('Error 2')
        progress.add_error(error2)

        expect(progress.errors.size).to eq(2)
        expect(progress.errors[0]).to eq('Error 1')
        expect(progress.errors[1]).to be_a(RuntimeError)
        expect(progress.has_errors?).to be true
      end
    end

    describe '#elapsed' do
      it 'returns elapsed time' do
        progress = described_class.new
        sleep(0.01)
        expect(progress.elapsed).to be >= 0.01
      end
    end

    describe '#rate' do
      it 'calculates processing rate' do
        progress = described_class.new
        progress.instance_variable_set(:@processed, 100)
        progress.instance_variable_set(:@started_at, Time.now - 10)

        expect(progress.rate).to be_within(1).of(10.0)
      end

      it 'returns 0 when no time elapsed' do
        progress = described_class.new
        expect(progress.rate).to eq(0)
      end
    end

    describe '#estimated_remaining' do
      it 'calculates estimated time remaining' do
        progress = described_class.new(total: 100)
        progress.instance_variable_set(:@processed, 50)
        progress.instance_variable_set(:@started_at, Time.now - 5)

        # At 10 items/sec, 50 remaining = ~5 seconds
        expect(progress.estimated_remaining).to be_within(1).of(5.0)
      end

      it 'returns nil when total unknown' do
        progress = described_class.new
        expect(progress.estimated_remaining).to be_nil
      end
    end

    describe '#percentage' do
      it 'calculates completion percentage' do
        progress = described_class.new(total: 200)
        progress.instance_variable_set(:@processed, 50)
        expect(progress.percentage).to eq(25.0)
      end

      it 'returns nil when total unknown' do
        progress = described_class.new
        expect(progress.percentage).to be_nil
      end
    end

    describe '#to_s' do
      it 'formats progress string' do
        progress = described_class.new(total: 100)
        progress.instance_variable_set(:@processed, 50)
        str = progress.to_s
        expect(str).to include('50 processed')
        expect(str).to include('of 100')
        expect(str).to include('(50.0%)')
      end
    end
  end

  describe Coradoc::Streaming::ChunkProcessor do
    describe '#initialize' do
      it 'uses default chunk size' do
        processor = described_class.new
        expect(processor.chunk_size).to eq(100)
      end

      it 'uses custom chunk size' do
        processor = described_class.new(chunk_size: 50)
        expect(processor.chunk_size).to eq(50)
      end
    end

    describe '#process' do
      it 'accumulates items until chunk is full' do
        processor = described_class.new(chunk_size: 3)
        chunks = []

        5.times { |i| processor.process(i) { |chunk| chunks << chunk } }

        expect(chunks).to eq([[0, 1, 2]])
      end
    end

    describe '#flush' do
      it 'flushes remaining items' do
        processor = described_class.new(chunk_size: 10)
        chunks = []

        3.times { |i| processor.process(i) { |chunk| chunks << chunk } }
        processor.flush { |chunk| chunks << chunk }

        expect(chunks).to eq([[0, 1, 2]])
        expect(processor.progress.processed).to eq(3)
      end

      it 'does nothing when no items' do
        processor = described_class.new
        called = false
        processor.flush { |_| called = true }
        expect(called).to be false
      end
    end
  end

  describe Coradoc::Streaming::MemoryMonitor do
    describe '.current_usage' do
      it 'returns memory usage' do
        usage = described_class.current_usage
        expect(usage).to be_an(Integer)
      end
    end

    describe '.exceeds_limit?' do
      it 'checks if memory exceeds limit' do
        # Very low limit should be exceeded
        expect(described_class.exceeds_limit?(1)).to be true

        # Very high limit should not be exceeded
        expect(described_class.exceeds_limit?(10 * 1024 * 1024 * 1024)).to be false
      end
    end

    describe '.stats' do
      it 'returns GC stats' do
        stats = described_class.stats
        expect(stats).to be_a(Hash)
      end
    end
  end

  describe Coradoc::Streaming::StreamReader do
    describe '.read_lines' do
      it 'reads file line by line' do
        Tempfile.create('test') do |f|
          f.write("line1\nline2\nline3\n")
          f.rewind

          lines = []
          progress = described_class.read_lines(f.path) { |line| lines << line }

          expect(lines).to eq(%W[line1\n line2\n line3\n])
          expect(progress.processed).to eq(3)
        end
      end
    end

    describe '.read_chunks' do
      it 'reads file in chunks' do
        Tempfile.create('test') do |f|
          f.write((1..10).map { |i| "line#{i}\n" }.join)
          f.rewind

          chunks = []
          progress = described_class.read_chunks(f.path, chunk_size: 3) do |chunk|
            chunks << chunk
          end

          expect(chunks.size).to eq(4) # 3+3+3+1
          expect(chunks.first.size).to eq(3)
          expect(chunks.last.size).to eq(1)
          expect(progress.processed).to eq(10)
        end
      end
    end
  end

  describe Coradoc::Streaming::StreamWriter do
    describe '#write' do
      it 'writes content to stream' do
        io = StringIO.new
        writer = described_class.new(io)

        bytes = writer.write('Hello')
        expect(bytes).to eq(5)
        expect(io.string).to eq('Hello')
        expect(writer.bytes_written).to eq(5)
      end
    end

    describe '#write_line' do
      it 'writes line with newline' do
        io = StringIO.new
        writer = described_class.new(io)

        writer.write_line('Hello')
        expect(io.string).to eq("Hello\n")
      end
    end

    describe '#flush' do
      it 'flushes the stream' do
        io = StringIO.new
        writer = described_class.new(io)

        # Should not raise
        writer.flush
      end
    end
  end

  describe 'module methods' do
    describe '.configuration' do
      it 'returns configuration' do
        config = described_class.configuration
        expect(config).to be_a(Coradoc::Streaming::Configuration)
      end
    end

    describe '.configure' do
      it 'yields configuration' do
        described_class.configure do |config|
          config.default_chunk_size = 50
        end

        expect(described_class.configuration.default_chunk_size).to eq(50)

        # Reset
        described_class.configuration.default_chunk_size = 100
      end
    end

    describe '.transform_in_chunks' do
      it 'transforms elements in chunks' do
        elements = (1..10).to_a
        result = described_class.transform_in_chunks(elements, chunk_size: 3) do |chunk|
          chunk.map { |n| n * 2 }
        end

        expect(result).to eq([2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
      end

      it 'returns elements as-is when no block' do
        elements = (1..5).to_a
        result = described_class.transform_in_chunks(elements, chunk_size: 2)
        expect(result).to eq(elements)
      end
    end

    describe '.serialize_incremental' do
      it 'serializes document incrementally' do
        # Skip if no format registered
        skip 'No format registered' unless Coradoc.registered_formats.include?(:html)

        chunks = []
        element = Coradoc::CoreModel::Block.new(
          delimiter_type: 'paragraph',
          content: 'Test content'
        )

        described_class.serialize_incremental(element, format: :html) do |chunk|
          chunks << chunk
        end

        expect(chunks).not_to be_empty
      end

      it 'raises error for unregistered format' do
        expect do
          described_class.serialize_incremental(double('doc'), format: :unknown) { |_| }
        end.to raise_error(Coradoc::UnsupportedFormatError)
      end
    end
  end
end
