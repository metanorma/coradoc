# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Plugin::Kotoshu::Checker do
  describe 'construction' do
    it 'raises when neither spellchecker nor language is given' do
      expect do
        described_class.new
      end.to raise_error(ArgumentError, /Provide either spellchecker: or language:/)
    end

    it 'accepts an injected spellchecker' do
      checker = described_class.new(spellchecker: build_spellchecker_for_specs)
      expect(checker.spellchecker).to respond_to(:check_word)
    end
  end

  describe '#check' do
    let(:checker) { build_checker_for_specs }

    it 'returns a Report' do
      report = checker.check('hello world', document: 'inline')
      expect(report).to be_a(Coradoc::Plugin::Kotoshu::Report)
    end

    it 'reports no errors for clean text' do
      report = checker.check('hello world ruby', document: 'inline')
      expect(report.error_count).to eq(0)
      expect(report).to be_clean
    end

    it 'captures misspelled words from paragraphs' do
      adoc = <<~ADOC
        = Title

        This paragraf contains helo.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      misspelled = report.errors.map(&:word)
      expect(misspelled).to include('paragraf')
      expect(misspelled).to include('helo')
    end

    it 'skips source code blocks' do
      adoc = <<~ADOC
        [source,ruby]
        ----
        misspelledword_should_be_skippedd
        ----
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      misspelled = report.errors.map(&:word)
      expect(misspelled).not_to include('misspelledword_should_be_skippedd')
    end

    it 'captures misspelled words in table cells' do
      adoc = <<~ADOC
        |===
        | Header A | Header Bee
        | celll one
        | celll twoo
        |===
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      misspelled = report.errors.map(&:word)
      expect(misspelled).to include('celll')
      expect(misspelled).to include('Bee')
    end

    it 'attaches a section label to errors' do
      adoc = <<~ADOC
        == My Section

        This paragraf has issues.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      para_error = report.errors.find { |e| e.word == 'paragraf' }
      expect(para_error.section).to eq('My Section')
    end

    it 'attaches an element label to errors' do
      adoc = <<~ADOC
        This paragraf.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      para_error = report.errors.find { |e| e.word == 'paragraf' }
      expect(para_error.element).to eq('paragraph')
    end

    it 'includes suggestions for misspellings' do
      adoc = <<~ADOC
        This paragraf.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      para_error = report.errors.find { |e| e.word == 'paragraf' }
      expect(para_error.suggestions).to include('paragraph')
    end

    it 'computes a best-effort line number' do
      adoc = <<~ADOC
        = Title

        First paragraph.

        This paragraf.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      para_error = report.errors.find { |e| e.word == 'paragraf' }
      expect(para_error.line).to eq(5)
    end

    it 'includes a context snippet around the misspelling' do
      adoc = <<~ADOC
        This paragraf is wrong.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      para_error = report.errors.find { |e| e.word == 'paragraf' }
      expect(para_error.context).to include('paragraf')
    end

    it 'counts words checked' do
      adoc = <<~ADOC
        hello world ruby
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      expect(report.word_count).to eq(3)
    end

    it 'aggregates counts in the report header' do
      adoc = <<~ADOC
        This paragraf and helo.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      expect(report.error_count).to eq(2)
      expect(report.unique_error_count).to eq(2)
    end

    it 'round-trips through YAML' do
      adoc = <<~ADOC
        This paragraf.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      yaml = report.to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed['document']).to eq('test.adoc')
      expect(parsed['errors'].first['word']).to eq('paragraf')
    end

    it 'round-trips through JSON' do
      adoc = <<~ADOC
        This paragraf.
      ADOC
      report = checker.check(adoc, document: 'test.adoc')
      json = JSON.parse(report.to_json)
      expect(json['document']).to eq('test.adoc')
      expect(json['errors'].first['word']).to eq('paragraf')
    end
  end

  describe '#check_file' do
    let(:checker) { build_checker_for_specs }

    it 'checks a file on disk' do
      report = checker.check_file(SAMPLE_ADOC)
      misspelled = report.errors.map(&:word)
      expect(misspelled).to include('paragraf')
      expect(misspelled).to include('helo')
      expect(misspelled).to include('oneo')
    end

    it 'tags the report with the file path' do
      report = checker.check_file(SAMPLE_ADOC)
      expect(report.document).to eq(SAMPLE_ADOC)
    end
  end
end
