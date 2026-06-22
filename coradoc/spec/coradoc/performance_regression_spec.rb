# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/performance_regression'

RSpec.describe Coradoc::PerformanceRegression do
  describe 'BenchmarkResult' do
    it 'formats a passing result line' do
      r = described_class::BenchmarkResult.new(name: 'x', duration: 0.1, iterations: 3, threshold: 2.0)
      expect(r.format_line).to eq('  PASS x: 0.1s (threshold: 2.0s)')
    end

    it 'formats a failing result line' do
      r = described_class::BenchmarkResult.new(name: 'x', duration: 5.0, iterations: 3, threshold: 2.0)
      expect(r.format_line).to eq('  FAIL x: 5.0s (threshold: 2.0s)')
    end
  end

  describe 'ComparisonResult' do
    it 'formats an OK line when within baseline' do
      r = described_class::ComparisonResult.new(name: 'x', duration: 0.12, baseline: 0.1)
      expect(r.format_line).to eq('  OK x: 0.12s (baseline: 0.1s)')
    end

    it 'formats a WARN line when regressed beyond 20%' do
      r = described_class::ComparisonResult.new(name: 'x', duration: 0.5, baseline: 0.1)
      expect(r.format_line).to eq('  WARN x: 0.5s (baseline: 0.1s)')
    end

    it 'reports no baseline when baseline is nil' do
      r = described_class::ComparisonResult.new(name: 'x', duration: 0.1, baseline: nil)
      expect(r.format_line).to eq('  OK x: 0.1s (no baseline)')
    end
  end

  describe '.print_results' do
    it 'accepts a summary Hash from run_all_with_summary' do
      result = described_class::BenchmarkResult.new(name: 'x', duration: 0.1, iterations: 3, threshold: 2.0)
      summary = { results: [result], failed_count: 0, total: 1 }
      expect { described_class.print_results(summary) }.to output(
        "  PASS x: 0.1s (threshold: 2.0s)\n\n1/1 passed\n"
      ).to_stdout
    end

    it 'accepts an Array of ComparisonResult from compare_with_baseline' do
      result = described_class::ComparisonResult.new(name: 'x', duration: 0.12, baseline: 0.1)
      expect { described_class.print_results([result]) }.to output(
        "  OK x: 0.12s (baseline: 0.1s)\n"
      ).to_stdout
    end
  end
end
