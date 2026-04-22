# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'json'

RSpec.describe Coradoc::PerformanceRegression do
  after do
    described_class.clear_benchmarks
  end

  describe '.define' do
    it 'defines a benchmark' do
      described_class.define(:test_benchmark) { 'test' }
      expect(described_class.benchmark_names).to include(:test_benchmark)
    end

    it 'accepts a threshold' do
      described_class.define(:test_benchmark, threshold: 0.5) { 'test' }
      expect(described_class.benchmark_names).to include(:test_benchmark)
    end
  end

  describe '.run' do
    it 'runs a benchmark and returns a Result' do
      described_class.define(:test_benchmark) { sleep(0.001) }
      result = described_class.run(:test_benchmark, iterations: 1)

      expect(result).to be_a(Coradoc::PerformanceRegression::Result)
      expect(result.name).to eq('test_benchmark')
      expect(result.duration).to be > 0
    end

    it 'returns error for undefined benchmark' do
      result = described_class.run(:nonexistent)

      expect(result.error).to include('not found')
      expect(result.duration).to be_nil
    end

    it 'captures benchmark errors' do
      described_class.define(:error_benchmark) { raise 'Test error' }
      result = described_class.run(:error_benchmark, iterations: 1)

      expect(result.error).to eq('Test error')
    end

    it 'runs multiple iterations' do
      call_count = 0
      described_class.define(:count_benchmark) { call_count += 1 }
      described_class.run(:count_benchmark, iterations: 3)

      expect(call_count).to eq(3)
    end
  end

  describe '.run_all' do
    it 'runs all defined benchmarks' do
      described_class.define(:benchmark1) { 1 }
      described_class.define(:benchmark2) { 2 }

      results = described_class.run_all(iterations: 1)

      expect(results.size).to eq(2)
      names = results.map(&:name)
      expect(names).to contain_exactly('benchmark1', 'benchmark2')
    end
  end

  describe '.run_all_with_summary' do
    it 'returns summary with passed and failed counts' do
      described_class.define(:fast_benchmark) { 1 }
      described_class.define(:slow_benchmark, threshold: 0.0001) { sleep(0.01) }

      summary = described_class.run_all_with_summary(iterations: 1)

      expect(summary).to have_key(:passed)
      expect(summary).to have_key(:failed)
      expect(summary).to have_key(:total)
      expect(summary[:total]).to eq(2)
    end
  end

  describe '.benchmark_names' do
    it 'returns list of benchmark names' do
      described_class.define(:benchmark1) { 1 }
      described_class.define(:benchmark2) { 2 }

      names = described_class.benchmark_names
      expect(names).to contain_exactly(:benchmark1, :benchmark2)
    end
  end

  describe '.clear_benchmarks' do
    it 'removes all defined benchmarks' do
      described_class.define(:benchmark1) { 1 }
      described_class.clear_benchmarks

      expect(described_class.benchmark_names).to eq([])
    end
  end

  describe '.save_baseline and .load_baseline' do
    it 'saves and loads baseline results' do
      described_class.define(:test_benchmark) { 1 }
      described_class.run_all(iterations: 1)

      Tempfile.create(['baseline', '.json']) do |file|
        described_class.save_baseline(file.path)

        expect(File.exist?(file.path)).to be true

        loaded = described_class.load_baseline(file.path)
        expect(loaded).to have_key(:test_benchmark)
        expect(loaded[:test_benchmark]).to be_a(Coradoc::PerformanceRegression::Result)
      end
    end

    it 'returns empty hash for non-existent file' do
      loaded = described_class.load_baseline('/nonexistent/path.json')
      expect(loaded).to eq({})
    end
  end

  describe '.compare_with_baseline' do
    it 'compares current results against baseline' do
      described_class.define(:test_benchmark) { 1 }

      Tempfile.create(['baseline', '.json']) do |file|
        # Save baseline
        described_class.save_baseline(file.path)

        # Compare
        results = described_class.compare_with_baseline(file.path, iterations: 1)

        expect(results.first.baseline).not_to be_nil
      end
    end
  end

  describe '.print_results' do
    it 'prints results to stdout' do
      described_class.define(:test_benchmark) { 1 }
      results = described_class.run_all(iterations: 1)

      expect { described_class.print_results(results) }.to output(/test_benchmark/).to_stdout
    end

    it 'accepts summary hash' do
      described_class.define(:test_benchmark) { 1 }
      summary = described_class.run_all_with_summary(iterations: 1)

      expect { described_class.print_results(summary) }.to output(/test_benchmark/).to_stdout
    end
  end
end

RSpec.describe Coradoc::PerformanceRegression::Result do
  describe '#initialize' do
    it 'stores benchmark name' do
      result = described_class.new('test_benchmark', duration: 0.1)
      expect(result.name).to eq('test_benchmark')
    end

    it 'stores duration' do
      result = described_class.new('test', duration: 0.123)
      expect(result.duration).to eq(0.123)
    end

    it 'stores threshold' do
      result = described_class.new('test', duration: 0.1, threshold: 0.5)
      expect(result.threshold).to eq(0.5)
    end

    it 'stores baseline' do
      result = described_class.new('test', duration: 0.1, baseline: 0.08)
      expect(result.baseline).to eq(0.08)
    end

    it 'stores error' do
      result = described_class.new('test', duration: nil, error: 'Test error')
      expect(result.error).to eq('Test error')
    end
  end

  describe '#exceeded_threshold?' do
    it 'returns true when duration exceeds threshold' do
      result = described_class.new('test', duration: 0.6, threshold: 0.5)
      expect(result.exceeded_threshold?).to be true
    end

    it 'returns false when duration is within threshold' do
      result = described_class.new('test', duration: 0.4, threshold: 0.5)
      expect(result.exceeded_threshold?).to be false
    end

    it 'returns false when no threshold' do
      result = described_class.new('test', duration: 0.1)
      expect(result.exceeded_threshold?).to be false
    end
  end

  describe '#regressed?' do
    it 'returns true when duration regresses from baseline' do
      result = described_class.new('test', duration: 0.15, baseline: 0.1)
      # 50% regression, threshold 20% -> 50% > 20% -> regressed
      expect(result.regressed?(0.2)).to be true
      # 50% regression, threshold 60% -> 50% < 60% -> not regressed
      expect(result.regressed?(0.6)).to be false
    end

    it 'returns false when no regression' do
      result = described_class.new('test', duration: 0.11, baseline: 0.1)
      expect(result.regressed?(0.2)).to be false # 10% regression, within 20%
    end

    it 'returns false when no baseline' do
      result = described_class.new('test', duration: 0.1)
      expect(result.regressed?).to be false
    end
  end

  describe '#failed?' do
    it 'returns true when has error' do
      result = described_class.new('test', duration: nil, error: 'Error')
      expect(result.failed?).to be true
    end

    it 'returns true when exceeded threshold' do
      result = described_class.new('test', duration: 0.6, threshold: 0.5)
      expect(result.failed?).to be true
    end

    it 'returns true when regressed beyond limit' do
      result = described_class.new('test', duration: 0.15, baseline: 0.1)
      # 50% regression, threshold 30% -> 50% > 30% -> failed
      expect(result.failed?(0.3)).to be true
      # 50% regression, threshold 60% -> 50% < 60% -> not failed
      expect(result.failed?(0.6)).to be false
    end

    it 'returns false when passing' do
      result = described_class.new('test', duration: 0.1, threshold: 0.5, baseline: 0.09)
      expect(result.failed?).to be false
    end
  end

  describe '#memory_delta' do
    it 'calculates memory difference' do
      result = described_class.new('test', duration: 0.1, memory_before: 1000, memory_after: 1500)
      expect(result.memory_delta).to eq(500)
    end

    it 'returns nil when memory values are nil' do
      result = described_class.new('test', duration: 0.1)
      expect(result.memory_delta).to be_nil
    end
  end

  describe '#to_h and .from_h' do
    it 'serializes and deserializes correctly' do
      original = described_class.new(
        'test',
        duration: 0.1,
        threshold: 0.5,
        baseline: 0.08,
        iterations: 3,
        memory_before: 1000,
        memory_after: 1500
      )

      hash = original.to_h
      restored = described_class.from_h(hash)

      expect(restored.name).to eq(original.name)
      expect(restored.duration).to eq(original.duration)
      expect(restored.threshold).to eq(original.threshold)
      expect(restored.baseline).to eq(original.baseline)
      expect(restored.iterations).to eq(original.iterations)
      expect(restored.memory_before).to eq(original.memory_before)
      expect(restored.memory_after).to eq(original.memory_after)
    end
  end
end
