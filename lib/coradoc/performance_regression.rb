# frozen_string_literal: true

require 'benchmark'
require 'json'

module Coradoc
  # Performance regression testing framework for CI integration.
  #
  # This module provides utilities to benchmark Coradoc operations and
  # detect performance regressions. It can be integrated into CI pipelines
  # to ensure code changes don't degrade performance beyond acceptable limits.
  #
  # @example Run benchmarks with thresholds
  #   results = Coradoc::PerformanceRegression.run_all
  #   exit(1) if results.any?(&:failed?)
  #
  # @example Run specific benchmark
  #   result = Coradoc::PerformanceRegression.run(:parse_asciidoc_small)
  #   puts "#{result.name}: #{result.duration}s (threshold: #{result.threshold}s)"
  #
  # @example Save baseline for comparison
  #   Coradoc::PerformanceRegression.save_baseline(".performance_baseline.json")
  #
  # @example Compare against baseline
  #   results = Coradoc::PerformanceRegression.compare_with_baseline(".performance_baseline.json")
  #
  module PerformanceRegression
    # Maximum allowed regression percentage (e.g., 0.2 = 20% slower allowed)
    MAX_REGRESSION_PERCENT = 0.2

    # Number of iterations for each benchmark
    BENCHMARK_ITERATIONS = 5

    # Represents a single benchmark result
    class Result
      attr_reader :name, :duration, :threshold, :baseline, :iterations,
                  :memory_before, :memory_after, :error

      # Create a new benchmark result
      #
      # @param name [String] The benchmark name
      # @param duration [Float] Average duration in seconds
      # @param threshold [Float, nil] Maximum allowed duration
      # @param baseline [Float, nil] Baseline duration for comparison
      # @param iterations [Integer] Number of iterations run
      # @param memory_before [Integer, nil] Memory usage before (bytes)
      # @param memory_after [Integer, nil] Memory usage after (bytes)
      # @param error [String, nil] Error message if benchmark failed
      def initialize(name, duration:, threshold: nil, baseline: nil, iterations: 1,
                     memory_before: nil, memory_after: nil, error: nil)
        @name = name
        @duration = duration
        @threshold = threshold
        @baseline = baseline
        @iterations = iterations
        @memory_before = memory_before
        @memory_after = memory_after
        @error = error
      end

      # Check if benchmark exceeded threshold
      #
      # @return [Boolean]
      def exceeded_threshold?
        return false if threshold.nil? || duration.nil?

        duration > threshold
      end

      # Check if benchmark regressed from baseline
      #
      # @param max_regression [Float] Maximum allowed regression (0.0-1.0)
      # @return [Boolean]
      def regressed?(max_regression = MAX_REGRESSION_PERCENT)
        return false if baseline.nil? || duration.nil?

        duration > baseline * (1 + max_regression)
      end

      # Check if benchmark failed (error or exceeded threshold or regressed)
      #
      # @param max_regression [Float] Maximum allowed regression
      # @return [Boolean]
      def failed?(max_regression = MAX_REGRESSION_PERCENT)
        !error.nil? || exceeded_threshold? || regressed?(max_regression)
      end

      # Get memory delta in bytes
      #
      # @return [Integer, nil]
      def memory_delta
        return nil if memory_before.nil? || memory_after.nil?

        memory_after - memory_before
      end

      # Convert to hash for serialization
      #
      # @return [Hash]
      def to_h
        {
          name: name,
          duration: duration,
          threshold: threshold,
          baseline: baseline,
          iterations: iterations,
          memory_before: memory_before,
          memory_after: memory_after,
          memory_delta: memory_delta,
          error: error
        }
      end

      # Create from hash
      #
      # @param hash [Hash]
      # @return [Result]
      def self.from_h(hash)
        new(
          hash[:name],
          duration: hash[:duration],
          threshold: hash[:threshold],
          baseline: hash[:baseline],
          iterations: hash[:iterations] || 1,
          memory_before: hash[:memory_before],
          memory_after: hash[:memory_after],
          error: hash[:error]
        )
      end
    end

    class << self
      # Define a benchmark
      #
      # @param name [Symbol] Unique benchmark name
      # @param threshold [Float] Maximum allowed duration in seconds
      # @yield The benchmark block
      # @return [void]
      def define(name, threshold: nil, &block)
        benchmarks[name] = { threshold: threshold, block: block }
      end

      # Run a specific benchmark
      #
      # @param name [Symbol] The benchmark name
      # @param iterations [Integer] Number of iterations
      # @return [Result]
      def run(name, iterations: BENCHMARK_ITERATIONS)
        benchmark = benchmarks[name]
        return Result.new(name.to_s, duration: nil, error: "Benchmark not found: #{name}") unless benchmark

        block = benchmark[:block]
        threshold = benchmark[:threshold]

        begin
          durations = []
          memory_before = memory_usage

          iterations.times do
            GC.start
            duration = Benchmark.realtime { block.call }
            durations << duration
          end

          memory_after = memory_usage
          avg_duration = durations.sum / durations.size

          Result.new(
            name.to_s,
            duration: avg_duration,
            threshold: threshold,
            iterations: iterations,
            memory_before: memory_before,
            memory_after: memory_after
          )
        rescue StandardError => e
          Result.new(name.to_s, duration: nil, error: e.message)
        end
      end

      # Run all defined benchmarks
      #
      # @param iterations [Integer] Number of iterations per benchmark
      # @return [Array<Result>]
      def run_all(iterations: BENCHMARK_ITERATIONS)
        benchmarks.keys.map { |name| run(name, iterations: iterations) }
      end

      # Run all benchmarks and return summary
      #
      # @param iterations [Integer] Number of iterations
      # @param max_regression [Float] Maximum allowed regression
      # @return [Hash] Summary with :passed, :failed, :results
      def run_all_with_summary(iterations: BENCHMARK_ITERATIONS,
                               max_regression: MAX_REGRESSION_PERCENT)
        results = run_all(iterations: iterations)
        failed = results.select { |r| r.failed?(max_regression) }
        passed = results.reject { |r| r.failed?(max_regression) }

        {
          passed: passed,
          failed: failed,
          results: results,
          total: results.size,
          passed_count: passed.size,
          failed_count: failed.size
        }
      end

      # Save baseline results to a file
      #
      # @param path [String] File path
      # @return [void]
      def save_baseline(path)
        results = run_all
        data = results.map(&:to_h)
        File.write(path, JSON.pretty_generate(data))
      end

      # Load baseline from a file
      #
      # @param path [String] File path
      # @return [Hash<Symbol, Result>]
      def load_baseline(path)
        return {} unless File.exist?(path)

        data = JSON.parse(File.read(path))
        data.each_with_object({}) do |h, acc|
          result = Result.from_h(h.transform_keys(&:to_sym))
          acc[result.name.to_sym] = result
        end
      end

      # Compare current performance against baseline
      #
      # @param path [String] Baseline file path
      # @param max_regression [Float] Maximum allowed regression
      # @param iterations [Integer] Number of iterations
      # @return [Array<Result>] Results with baseline set
      def compare_with_baseline(path, max_regression: MAX_REGRESSION_PERCENT,
                                iterations: BENCHMARK_ITERATIONS)
        baseline = load_baseline(path)
        results = run_all(iterations: iterations)

        results.map do |result|
          baseline_result = baseline[result.name.to_sym]
          next result unless baseline_result

          Result.new(
            result.name,
            duration: result.duration,
            threshold: result.threshold,
            baseline: baseline_result.duration,
            iterations: result.iterations,
            memory_before: result.memory_before,
            memory_after: result.memory_after,
            error: result.error
          )
        end
      end

      # Print results to stdout
      #
      # @param results [Array<Result>, Hash]
      # @return [void]
      def print_results(results)
        results = results[:results] if results.is_a?(Hash)

        puts "\n=== Performance Regression Results ===\n"
        printf "%-40s %10s %10s %10s %8s\n", 'Benchmark', 'Duration', 'Threshold', 'Baseline', 'Status'
        puts '-' * 80

        results.each do |r|
          status = if r.error
                     'ERROR'
                   elsif r.failed?
                     'FAILED'
                   else
                     'PASS'
                   end

          printf "%-40s %10.4f %10.4f %10s %8s\n",
                 r.name,
                 r.duration || 0,
                 r.threshold || 0,
                 r.baseline ? format('%.4f', r.baseline) : '-',
                 status

          if r.error
            puts "  Error: #{r.error}"
          elsif r.regressed?
            regression_pct = ((r.duration - r.baseline) / r.baseline * 100).round(1)
            puts "  Regression: #{regression_pct}% slower than baseline"
          end
        end

        puts
      end

      # Get all defined benchmark names
      #
      # @return [Array<Symbol>]
      def benchmark_names
        benchmarks.keys
      end

      # Clear all defined benchmarks
      #
      # @return [void]
      def clear_benchmarks
        @benchmarks = {}
      end

      private

      def benchmarks
        @benchmarks ||= {}
      end

      def memory_usage
        return nil unless defined?(GC)

        GC.start
        GC.stat[:total_allocated_objects]
      end
    end
  end

  # Private module for defining standard benchmarks
  module StandardBenchmarks
    def self.included(base)
      base.extend(ClassMethods)
      base.define_standard_benchmarks
    end

    module ClassMethods
      def define_standard_benchmarks
        # Only define if we have the required dependencies
        return unless defined?(Coradoc::AsciiDoc)

        # Small AsciiDoc parsing benchmark
        define :parse_asciidoc_small, threshold: 0.5 do
          adoc = <<~ADOC
            = Document Title

            == Section 1

            This is a paragraph with *bold* and _italic_ text.

            * Item 1
            * Item 2
            * Item 3
          ADOC

          Coradoc.parse(adoc, format: :asciidoc)
        end

        # Medium AsciiDoc parsing benchmark
        define :parse_asciidoc_medium, threshold: 2.0 do
          adoc = build_medium_adoc
          Coradoc.parse(adoc, format: :asciidoc)
        end

        # AsciiDoc to HTML conversion benchmark
        define :convert_asciidoc_to_html, threshold: 1.0 do
          adoc = build_small_adoc
          Coradoc.convert(adoc, from: :asciidoc, to: :html)
        end

        # Round-trip conversion benchmark (AsciiDoc → HTML → CoreModel → AsciiDoc)
        define :roundtrip_asciidoc, threshold: 1.0 do
          adoc = build_small_adoc
          html = Coradoc.convert(adoc, from: :asciidoc, to: :html)
          Coradoc.convert(html, from: :html, to: :asciidoc)
        end

        # CoreModel transformation benchmark
        define :transform_to_core_model, threshold: 0.5 do
          adoc = build_small_adoc
          doc = Coradoc::AsciiDoc.parse(adoc)
          Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
        end
      end

      private

      def build_small_adoc
        <<~ADOC
          = Document Title
          :toc: auto

          == Introduction

          This is an introduction paragraph.

          == Main Content

          === Subsection

          More content here with a list:

          * First item
          * Second item
          * Third item

          A code block:

          [source,ruby]
          ----
          def hello
            puts "Hello, World!"
          end
          ----
        ADOC
      end

      def build_medium_adoc
        sections = []
        sections << "= Large Document\n\n"

        20.times do |i|
          sections << "== Section #{i + 1}\n\n"
          sections << "This is the content for section #{i + 1}.\n\n"

          5.times do |j|
            sections << "* List item #{j + 1} in section #{i + 1}\n"
          end
          sections << "\n"

          sections << "[source,ruby]\n----\n"
          sections << "def method_#{i}\n  #{i + 1}\nend\n"
          sections << "----\n\n"
        end

        sections.join
      end
    end
  end

  # Include standard benchmarks
  PerformanceRegression.include(StandardBenchmarks)
end
