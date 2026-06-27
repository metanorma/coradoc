# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html do
  describe '.input_config' do
    it 'returns an InputConfig instance' do
      expect(described_class.input_config).to be_a(Coradoc::Html::InputConfig)
    end

    it 'yields config when block given' do
      described_class.input_config do |c|
        expect(c).to be_a(Coradoc::Html::InputConfig)
      end
    end

    it 'caches the same instance across calls' do
      expect(described_class.input_config).to equal(described_class.input_config)
    end

    it 'reset_input_config! clears the cache' do
      first = described_class.input_config
      described_class.reset_input_config!
      expect(described_class.input_config).not_to equal(first)
    end
  end

  describe '.cleaner' do
    it 'returns a Cleaner instance' do
      expect(described_class.cleaner).to be_a(Coradoc::Html::Cleaner)
    end
  end

  describe '.to_coradoc' do
    it 'converts HTML string to CoreModel elements' do
      html = '<h1>Title</h1><p>Content</p>'
      result = described_class.to_coradoc(html)
      expect(result).to be_a(Array)
    end
  end
end
