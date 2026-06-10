# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::RenderOptions do
  describe 'defaults' do
    subject { described_class.new }

    it 'defaults layout to :static' do
      expect(subject.layout).to eq(:static)
    end

    it 'defaults lang to en' do
      expect(subject.lang).to eq('en')
    end

    it 'defaults toc to false' do
      expect(subject.toc).to eq(false)
    end

    it 'defaults toc_levels to 2' do
      expect(subject.toc_levels).to eq(2)
    end

    it 'defaults section_numbers to false' do
      expect(subject.section_numbers).to eq(false)
    end

    it 'defaults section_number_levels to 3' do
      expect(subject.section_number_levels).to eq(3)
    end
  end

  describe 'initialization' do
    it 'accepts keyword arguments' do
      opts = described_class.new(lang: 'fr', toc: true, toc_levels: 4)
      expect(opts.lang).to eq('fr')
      expect(opts.toc).to eq(true)
      expect(opts.toc_levels).to eq(4)
    end

    it 'is frozen' do
      opts = described_class.new
      expect(opts).to be_frozen
    end

    it 'raises on mutation attempt' do
      opts = described_class.new(lang: 'en')
      expect { opts.instance_variable_set(:@lang, 'fr') }.to raise_error(FrozenError)
    end
  end

  describe '#spa?' do
    it 'returns true for spa layout' do
      expect(described_class.new(layout: :spa)).to be_spa
    end

    it 'returns false for static layout' do
      expect(described_class.new(layout: :static)).not_to be_spa
    end
  end

  describe '#static?' do
    it 'returns true for static layout' do
      expect(described_class.new(layout: :static)).to be_static
    end

    it 'returns false for spa layout' do
      expect(described_class.new(layout: :spa)).not_to be_static
    end
  end

  describe 'SPA options' do
    it 'carries dist_dir' do
      opts = described_class.new(dist_dir: '/tmp/dist')
      expect(opts.dist_dir).to eq('/tmp/dist')
    end

    it 'carries theme_toggle' do
      opts = described_class.new(theme_toggle: false)
      expect(opts.theme_toggle).to eq(false)
    end

    it 'carries reading_progress' do
      opts = described_class.new(reading_progress: false)
      expect(opts.reading_progress).to eq(false)
    end

    it 'defaults theme_toggle to true' do
      expect(described_class.new.theme_toggle).to eq(true)
    end

    it 'defaults reading_progress to true' do
      expect(described_class.new.reading_progress).to eq(true)
    end
  end

  describe 'static options' do
    it 'carries author' do
      opts = described_class.new(author: 'John')
      expect(opts.author).to eq('John')
    end

    it 'carries description' do
      opts = described_class.new(description: 'A doc')
      expect(opts.description).to eq('A doc')
    end

    it 'carries custom_css' do
      opts = described_class.new(custom_css: 'body { color: red }')
      expect(opts.custom_css).to eq('body { color: red }')
    end
  end
end
