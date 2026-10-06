# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe 'Corpus benchmarks', type: :benchmark do
  # Representative-corpus measurement harness (TODO.inhouseparsing 09).
  # Unlike performance_spec.rb (threshold regression tests), this spec
  # MEASURES per-stage timings over realistic documents and prints a
  # table — record numbers in PR descriptions, don't gate on them.
  #
  #   BENCHMARK=true bundle exec rspec spec/benchmark/corpus_spec.rb
  #
  # Stages: parse-only, parse+transform (→ CoreModel), end-to-end
  # (convert both directions). The native-engine lane is opt-in via
  # CORADOC_BENCH_NATIVE=1 — run it under the RSS watchdog
  # (memwatch_kill.sh); table-bearing documents are excluded there
  # until parsanol-rs#174 (catastrophic native backtracking) is fixed.

  def ad_iterations
    3
  end

  def corpus_docs
    Dir[File.expand_path('../fixtures/metanorma_org_posts/*.adoc', __dir__)]
      .to_h { |p| [File.basename(p), File.read(p)] }
  end

  def corpus
    corpus_docs.merge(
      'synthetic-mixed.adoc' => build_synthetic_adoc,
      'synthetic-table-heavy.adoc' => build_table_heavy_adoc
    )
  end

  def build_synthetic_adoc
    <<~ADOC
      = Synthetic Corpus Document
      Author Name <author@example.com>
      v1.0, 2024-01-01

      == Introduction

      A paragraph with *bold*, _italic_, `mono`, and a link
      https://example.com/[here]. A footnotefootnote:[note] too.

      === Details

      [source,ruby]
      ----
      puts "hello"
      ----

      * item one
      * item two
      ** nested item
      +
      continuation paragraph

      NOTE: an admonition closes the document.
    ADOC
  end

  def build_table_heavy_adoc
    rows = (1..20).map { |i| "|r#{i}c1 |r#{i}c2 |r#{i}c3" }.join("\n")
    "|===\n|H1 |H2 |H3\n#{rows}\n|===\n"
  end

  def markdown_doc
    <<~MD
      # Markdown Corpus

      Paragraph with **bold**, _em_, and `code`.

      ## Section

      - list one
      - list two

      ```ruby
      puts 1
      ```
    MD
  end

  def html_doc
    <<~HTML
      <html><head><title>HTML Corpus</title></head>
      <body><h1>Heading</h1><p>Some <b>bold</b> text.</p>
      <ul><li>one</li><li>two</li></ul>
      <table><tr><td>a</td><td>b</td></tr></table></body></html>
    HTML
  end

  def report(label, iterations, doc_bytes, total)
    puts format(
      '  %-<label>42s %<ms>8.2f ms/op  %<kb>7.1f KB',
      label:, ms: (total / iterations) * 1000, kb: doc_bytes / 1024.0
    )
  end

  before(:all) do
    skip 'Benchmarks only run with BENCHMARK=true' unless ENV['BENCHMARK'] == 'true'
    require 'coradoc/asciidoc'
    require 'coradoc/html'
    require 'coradoc/markdown'
  end

  describe 'AsciiDoc corpus' do
    it 'measures parse-only, parse+transform, and end-to-end per document' do
      corpus.each do |name, doc|
        bytes = doc.bytesize
        parser = Coradoc::AsciiDoc::Parser::Base.new

        t = Benchmark.measure { ad_iterations.times { parser.parse(doc) } }
        report("adoc parse-only   #{name}", ad_iterations, bytes, t.real)

        t = Benchmark.measure { ad_iterations.times { Coradoc.parse(doc, format: :asciidoc) } }
        report("adoc → CoreModel   #{name}", ad_iterations, bytes, t.real)

        t = Benchmark.measure { ad_iterations.times { Coradoc.convert(doc, from: :asciidoc, to: :html) } }
        report("adoc → html        #{name}", ad_iterations, bytes, t.real)
      end
    end

    it 'measures the native parse lane (opt-in, table docs excluded)' do
      skip 'set CORADOC_BENCH_NATIVE=1 (run under the RSS watchdog)' unless ENV['CORADOC_BENCH_NATIVE'] == '1'

      parser = Coradoc::AsciiDoc::Parser::Base.new
      corpus.each do |name, doc|
        next if name == 'synthetic-table-heavy.adoc' # parsanol-rs#174

        t = Benchmark.measure { ad_iterations.times { parser.parse(doc, mode: :native) } }
        report("adoc native parse  #{name}", ad_iterations, doc.bytesize, t.real)
      end
    end
  end

  describe 'Markdown corpus' do
    it 'measures parse and end-to-end' do
      doc = markdown_doc
      t = Benchmark.measure { ad_iterations.times { Coradoc::Markdown.parse(doc) } }
      report('md parse-only', ad_iterations, doc.bytesize, t.real)

      t = Benchmark.measure { ad_iterations.times { Coradoc.convert(doc, from: :markdown, to: :html) } }
      report('md → html', ad_iterations, doc.bytesize, t.real)
    end
  end

  describe 'HTML corpus' do
    it 'measures parse-to-core and html→adoc' do
      doc = html_doc
      t = Benchmark.measure { ad_iterations.times { Coradoc.parse(doc, format: :html) } }
      report('html → CoreModel', ad_iterations, doc.bytesize, t.real)

      t = Benchmark.measure { ad_iterations.times { Coradoc.convert(doc, from: :html, to: :asciidoc) } }
      report('html → adoc', ad_iterations, doc.bytesize, t.real)
    end
  end
end
