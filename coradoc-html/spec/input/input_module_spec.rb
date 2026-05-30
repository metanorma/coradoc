# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Input::Html do
  describe '.config' do
    it 'returns a Config instance' do
      expect(described_class.config).to be_a(Coradoc::Input::Html::Config)
    end

    it 'yields config when block given' do
      described_class.config do |c|
        expect(c).to be_a(Coradoc::Input::Html::Config)
      end
    end
  end

  describe '.processor_id' do
    it 'returns :html' do
      expect(described_class.processor_id).to eq(:html)
    end
  end

  describe '.processor_match?' do
    it 'matches .html files' do
      expect(described_class.processor_match?('doc.html')).to be true
    end

    it 'matches .htm files' do
      expect(described_class.processor_match?('doc.htm')).to be true
    end

    it 'does not match other extensions' do
      expect(described_class.processor_match?('doc.md')).to be false
    end
  end

  describe '.processor_execute' do
    it 'converts HTML to CoreModel elements' do
      html = '<p>Hello</p>'
      result = described_class.processor_execute(html, {})
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Coradoc::CoreModel::Base)
    end
  end

  describe '.to_coradoc' do
    it 'converts HTML string to CoreModel elements' do
      html = '<h1>Title</h1><p>Content</p>'
      result = described_class.to_coradoc(html)
      expect(result).to be_a(Array)
    end
  end

  describe '.clean_output' do
    it 'cleans up extra whitespace' do
      input = "Hello\n\n\n\nWorld"
      result = described_class.clean_output(input, {})

      expect(result).not_to include("\n\n\n")
    end
  end
end
