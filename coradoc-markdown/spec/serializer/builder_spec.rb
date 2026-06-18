# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Serializer::Builder do
  let(:element) { Coradoc::Markdown::Paragraph.new(text: 'Hello') }

  describe '#initialize' do
    it 'defaults to :gfm flavor' do
      runner = described_class.new.runner
      expect(runner.config.markdown_flavor).to eq(:gfm)
    end

    it 'accepts a custom flavor' do
      runner = described_class.new(:vitepress).runner
      expect(runner.config.markdown_flavor).to eq(:vitepress)
    end
  end

  describe 'attribute setters' do
    it 'captures admonition_style overrides' do
      builder = described_class.new
      builder.admonition_style = :container
      expect(builder.runner.config.admonition_style).to eq(:container)
    end

    it 'captures suppress_comments overrides' do
      builder = described_class.new
      builder.suppress_comments = false
      expect(builder.runner.config.suppress_comments).to eq(false)
    end

    it 'captures autolinks overrides' do
      builder = described_class.new
      builder.autolinks = false
      expect(builder.runner.config.autolinks).to eq(false)
    end

    it 'captures definition_list_nested overrides' do
      builder = described_class.new
      builder.definition_list_nested = :flatten
      expect(builder.runner.config.definition_list_nested).to eq(:flatten)
    end
  end

  describe '#apply' do
    it 'merges a hash of overrides' do
      runner = described_class.new.apply(admonition_style: :html, autolinks: false).runner
      expect(runner.config.admonition_style).to eq(:html)
      expect(runner.config.autolinks).to eq(false)
    end
  end

  describe '#call' do
    it 'serializes via the configured runner' do
      expect(described_class.new.call(element)).to eq('Hello')
    end
  end

  describe 'integration with Serializer.build' do
    it 'invokes a config block' do
      runner = Coradoc::Markdown::Serializer.build(:gfm) do |config|
        config.suppress_comments = false
      end
      expect(runner.config.suppress_comments).to eq(false)
    end
  end
end
