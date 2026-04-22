# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Memory do
  describe Coradoc::Memory::Snapshot do
    describe '.take' do
      it 'creates a memory snapshot' do
        snapshot = described_class.take

        expect(snapshot.timestamp).to be_a(Time)
        expect(snapshot.allocated_objects).to be_an(Integer)
        expect(snapshot.heap_slots).to be_an(Integer)
        expect(snapshot.heap_slots_live).to be_an(Integer)
        expect(snapshot.total_memsize).to be_an(Integer)
        expect(snapshot.gc_count).to be_an(Integer)
      end
    end

    describe '#diff' do
      it 'calculates difference from another snapshot' do
        snapshot1 = described_class.take
        # Allocate some objects
        100.times { "test string #{rand}" }
        snapshot2 = described_class.take

        diff = snapshot2.diff(snapshot1)

        expect(diff).to have_key(:elapsed)
        expect(diff).to have_key(:allocated_delta)
        expect(diff).to have_key(:heap_delta)
        expect(diff).to have_key(:live_delta)
        expect(diff).to have_key(:memsize_delta)
        expect(diff).to have_key(:gc_runs)
        expect(diff[:elapsed]).to be >= 0
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        snapshot = described_class.take
        hash = snapshot.to_h

        expect(hash[:timestamp]).to be_a(Time)
        expect(hash[:allocated_objects]).to be_an(Integer)
        expect(hash[:heap_slots]).to be_an(Integer)
        expect(hash[:heap_slots_live]).to be_an(Integer)
        expect(hash[:total_memsize]).to be_an(Integer)
        expect(hash[:gc_count]).to be_an(Integer)
      end
    end
  end

  describe Coradoc::Memory::Tracker do
    describe '#initialize' do
      it 'creates tracker with default settings' do
        tracker = described_class.new
        expect(tracker.checkpoints).to eq([])
      end

      it 'creates tracker with auto_gc option' do
        tracker = described_class.new(auto_gc: false)
        expect(tracker.checkpoints).to eq([])
      end
    end

    describe '#checkpoint' do
      it 'records a checkpoint' do
        tracker = described_class.new

        tracker.checkpoint('start')
        expect(tracker.checkpoints.size).to eq(1)
        expect(tracker.checkpoints.first[:name]).to eq('start')
        expect(tracker.checkpoints.first[:snapshot]).to be_a(Coradoc::Memory::Snapshot)
      end

      it 'records multiple checkpoints' do
        tracker = described_class.new

        tracker.checkpoint('start')
        10.times { 'test' }
        tracker.checkpoint('middle')
        10.times { 'test' }
        tracker.checkpoint('end')

        expect(tracker.checkpoints.size).to eq(3)
        expect(tracker.checkpoints.map { |cp| cp[:name] }).to eq(%w[start middle end])
      end
    end

    describe '#deltas' do
      it 'returns empty array for single checkpoint' do
        tracker = described_class.new
        tracker.checkpoint('only')
        expect(tracker.deltas).to eq([])
      end

      it 'calculates deltas between checkpoints' do
        tracker = described_class.new

        tracker.checkpoint('start')
        50.times { "test string #{rand}" }
        tracker.checkpoint('end')

        deltas = tracker.deltas
        expect(deltas.size).to eq(1)
        expect(deltas.first[:from]).to eq('start')
        expect(deltas.first[:to]).to eq('end')
        expect(deltas.first[:delta]).to have_key(:elapsed)
        expect(deltas.first[:delta]).to have_key(:allocated_delta)
      end
    end

    describe '#report' do
      it 'returns message for no checkpoints' do
        tracker = described_class.new
        expect(tracker.report).to eq('No checkpoints recorded')
      end

      it 'generates report for single checkpoint' do
        tracker = described_class.new
        tracker.checkpoint('only')

        report = tracker.report
        expect(report).to include('Single checkpoint: only')
        expect(report).to include('Allocated objects:')
      end

      it 'generates report for multiple checkpoints' do
        tracker = described_class.new

        tracker.checkpoint('start')
        10.times { 'test' }
        tracker.checkpoint('middle')
        10.times { 'test' }
        tracker.checkpoint('end')

        report = tracker.report
        expect(report).to include('Memory Profile Report')
        expect(report).to include('start -> middle')
        expect(report).to include('middle -> end')
        expect(report).to include('Total:')
      end
    end
  end

  describe Coradoc::Memory::ProfileResult do
    describe '#initialize' do
      it 'creates profile result' do
        result = described_class.new(
          allocated: 1000,
          retained: 500,
          peak: 1500,
          duration: 0.5
        )

        expect(result.allocated).to eq(1000)
        expect(result.retained).to eq(500)
        expect(result.peak).to eq(1500)
        expect(result.duration).to eq(0.5)
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        result = described_class.new(
          allocated: 1000,
          retained: 500,
          peak: 1500,
          duration: 0.5
        )

        hash = result.to_h
        expect(hash[:allocated]).to eq(1000)
        expect(hash[:retained]).to eq(500)
        expect(hash[:peak]).to eq(1500)
        expect(hash[:duration]).to eq(0.5)
      end
    end

    describe '#to_s' do
      it 'formats as string' do
        result = described_class.new(
          allocated: 1000,
          retained: 500,
          peak: 1500,
          duration: 0.5
        )

        str = result.to_s
        expect(str).to include('Allocated:')
        expect(str).to include('Retained:')
        expect(str).to include('Peak:')
        expect(str).to include('Duration:')
      end
    end
  end

  describe 'module methods' do
    describe '.current_usage' do
      it 'returns current memory usage' do
        usage = described_class.current_usage
        expect(usage).to be_an(Integer)
        expect(usage).to be >= 0
      end
    end

    describe '.stats' do
      it 'returns detailed memory statistics' do
        stats = described_class.stats

        expect(stats).to be_a(Hash)
        expect(stats).to have_key(:total_allocated_objects)
        expect(stats).to have_key(:heap_sorted_length)
        expect(stats).to have_key(:heap_live_slots)
        expect(stats).to have_key(:gc_count)
      end
    end

    describe '.profile' do
      it 'profiles a block of code' do
        result = described_class.profile do
          100.times { "test string #{rand}" }
        end

        expect(result).to be_a(Coradoc::Memory::ProfileResult)
        expect(result.duration).to be >= 0
      end

      it 'respects gc_before option' do
        result = described_class.profile(gc_before: true, gc_after: true) do
          'test'
        end

        expect(result).to be_a(Coradoc::Memory::ProfileResult)
      end
    end

    describe '.tracker' do
      it 'creates a new tracker' do
        tracker = described_class.tracker
        expect(tracker).to be_a(Coradoc::Memory::Tracker)
      end

      it 'passes auto_gc option' do
        tracker = described_class.tracker(auto_gc: false)
        expect(tracker).to be_a(Coradoc::Memory::Tracker)
      end
    end

    describe '.snapshot' do
      it 'takes a memory snapshot' do
        snapshot = described_class.snapshot
        expect(snapshot).to be_a(Coradoc::Memory::Snapshot)
      end
    end

    describe '.gc_cleanup' do
      it 'runs garbage collection' do
        # Allocate some objects
        100.times { "test string #{rand}" }

        freed = described_class.gc_cleanup
        # Freed could be negative if GC.compact moved things
        expect(freed).to be_an(Integer)
      end
    end
  end
end
