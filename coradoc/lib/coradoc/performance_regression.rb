# frozen_string_literal: true

require 'benchmark'
require 'json'

module Coradoc
  module PerformanceRegression
    THRESHOLDS = {
      markdown_parse_small: 2.0,
      markdown_parse_medium: 3.0,
      asciidoc_parse: 5.0,
      html_serialize: 5.0,
      md_to_html: 10.0,
      adoc_to_html: 10.0,
      core_model_creation: 1.0
    }.freeze

    BenchmarkResult = Struct.new(:name, :duration, :iterations, :threshold, keyword_init: true) do
      def to_h
        { name:, duration:, iterations:, threshold:, passed: passed? }
      end

      def passed?
        duration < threshold
      end

      def format_line
        status = passed? ? 'PASS' : 'FAIL'
        "  #{status} #{name}: #{duration.round(4)}s (threshold: #{threshold}s)"
      end
    end

    ComparisonResult = Struct.new(:name, :duration, :baseline, keyword_init: true) do
      def regressed?(pct = 0.2)
        return false if baseline.nil? || baseline.zero?

        (duration - baseline).abs / baseline > pct
      end

      def format_line
        status = regressed? ? 'WARN' : 'OK'
        baseline_str = baseline ? "(baseline: #{baseline.round(4)}s)" : '(no baseline)'
        "  #{status} #{name}: #{duration.round(4)}s #{baseline_str}"
      end
    end

    class << self
      def run_all(iterations: 3)
        benchmarks = build_benchmarks
        benchmarks.map do |name, threshold, block|
          times = []
          iterations.times { times << Benchmark.realtime { block.call } }
          avg = times.sum / times.size
          BenchmarkResult.new(name:, duration: avg, iterations:, threshold:)
        end
      end

      def run_all_with_summary(iterations: 3)
        results = run_all(iterations:)
        failed = results.count { |r| !r.passed? }
        { results:, failed_count: failed, total: results.size }
      end

      def print_results(summary_or_results)
        if summary_or_results.is_a?(Hash)
          summary = summary_or_results
          summary[:results].each { |r| puts r.format_line }
          puts
          puts "#{summary[:total] - summary[:failed_count]}/#{summary[:total]} passed"
        else
          Array(summary_or_results).each { |r| puts r.format_line }
        end
      end

      def compare_with_baseline(baseline_path, iterations: 3)
        return [] unless File.exist?(baseline_path)

        baseline_data = JSON.parse(File.read(baseline_path))
        baseline_map = baseline_data.each_with_object({}) { |d, m| m[d['name']] = d['duration'] }

        results = run_all(iterations:)
        results.map do |r|
          ComparisonResult.new(name: r.name, duration: r.duration, baseline: baseline_map[r.name])
        end
      end

      private

      def build_benchmarks
        sample = {
          markdown_small: "# Title\n\n#{'Paragraph ' * 10}",
          markdown_medium: "# Title\n\n#{'Content. ' * 100}\n\n## Section\n\n#{'More. ' * 100}",
          asciidoc: "= Title\nAuthor\n\n== Section\n\n#{'Paragraph content. ' * 50}",
          html_doc: Coradoc::CoreModel::DocumentElement.new(
            title: 'Bench',
            children: [
              Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Test')
            ]
          )
        }

        [
          [:markdown_parse_small, THRESHOLDS[:markdown_parse_small],
           -> { Coradoc::Markdown.parse(sample[:markdown_small]) }],
          [:markdown_parse_medium, THRESHOLDS[:markdown_parse_medium],
           -> { Coradoc::Markdown.parse(sample[:markdown_medium]) }],
          [:asciidoc_parse, THRESHOLDS[:asciidoc_parse],
           -> { Coradoc.parse(sample[:asciidoc], format: :asciidoc) }],
          [:html_serialize, THRESHOLDS[:html_serialize],
           -> { Coradoc::Html.serialize_static(sample[:html_doc]) }],
          [:md_to_html, THRESHOLDS[:md_to_html],
           -> { Coradoc.convert(sample[:markdown_small], from: :markdown, to: :html) }],
          [:adoc_to_html, THRESHOLDS[:adoc_to_html],
           -> { Coradoc.convert(sample[:asciidoc], from: :asciidoc, to: :html) }],
          [:core_model_creation, THRESHOLDS[:core_model_creation],
           -> { 1000.times { Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'x') } }]
        ]
      end
    end
  end
end
