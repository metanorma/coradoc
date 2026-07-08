# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require 'json'

RSpec.describe Coradoc::Plugin::Kotoshu::Report do
  let(:error_attrs) do
    {
      word: 'helo',
      context: '...greeting: helo world...',
      element: 'paragraph',
      section: 'Intro',
      line: 12,
      suggestions: %w[hello help hell]
    }
  end

  describe 'construction' do
    it 'computes error_count from errors' do
      errors = [
        Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs),
        Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs, word: 'wrold')
      ]
      report = described_class.new(document: 'x.adoc', errors: errors)
      expect(report.error_count).to eq(2)
    end

    it 'computes unique_error_count from distinct words' do
      errors = [
        Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs),
        Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs),
        Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs, word: 'wrold')
      ]
      report = described_class.new(document: 'x.adoc', errors: errors)
      expect(report.error_count).to eq(3)
      expect(report.unique_error_count).to eq(2)
    end
  end

  describe 'predicates' do
    it 'clean? when no errors' do
      report = described_class.new(document: 'x.adoc', errors: [])
      expect(report).to be_clean
    end

    it 'not clean? with errors' do
      report = described_class.new(document: 'x.adoc',
                                   errors: [Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs)])
      expect(report).not_to be_clean
    end
  end

  describe 'serialization' do
    it 'round-trips through YAML with a kotoshu_report root' do
      report = described_class.new(
        document: 'x.adoc',
        language: 'en',
        generated_at: '2026-06-27T00:00:00Z',
        checker_version: '0.1.0',
        word_count: 100,
        errors: [Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs)]
      )
      yaml = report.to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed['document']).to eq('x.adoc')
      expect(parsed['language']).to eq('en')
      expect(parsed['word_count']).to eq(100)
      expect(parsed['errors'].first['word']).to eq('helo')
      expect(parsed['errors'].first['suggestions']).to eq(%w[hello help hell])
    end

    it 'round-trips through JSON' do
      report = described_class.new(
        document: 'x.adoc',
        errors: [Coradoc::Plugin::Kotoshu::ReportError.new(**error_attrs)]
      )
      parsed = JSON.parse(report.to_json)
      expect(parsed['document']).to eq('x.adoc')
      expect(parsed['errors'].first['word']).to eq('helo')
    end
  end
end

RSpec.describe Coradoc::Plugin::Kotoshu::ReportError do
  it 'exposes all attributes' do
    err = described_class.new(
      word: 'helo',
      context: '...',
      element: 'paragraph',
      section: 'Intro',
      line: 12,
      suggestions: %w[hello help]
    )
    expect(err.word).to eq('helo')
    expect(err.context).to eq('...')
    expect(err.element).to eq('paragraph')
    expect(err.section).to eq('Intro')
    expect(err.line).to eq(12)
    expect(err.suggestions).to eq(%w[hello help])
  end

  it 'has_suggestions? reflects the suggestions list' do
    no_sugg = described_class.new(word: 'xyz', suggestions: [])
    yes_sugg = described_class.new(word: 'helo', suggestions: ['hello'])
    expect(no_sugg).not_to have_suggestions
    expect(yes_sugg).to have_suggestions
  end
end
