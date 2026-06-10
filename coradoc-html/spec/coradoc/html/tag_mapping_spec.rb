# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::TagMapping do
  describe '.tag_for' do
    it 'maps paragraph to p' do
      expect(described_class.tag_for(:paragraph)).to eq('p')
    end

    it 'maps bold to strong' do
      expect(described_class.tag_for(:bold)).to eq('strong')
    end

    it 'maps italic to em' do
      expect(described_class.tag_for(:italic)).to eq('em')
    end

    it 'maps table to table' do
      expect(described_class.tag_for(:table)).to eq('table')
    end

    it 'maps source_code to pre' do
      expect(described_class.tag_for(:source_code)).to eq('pre')
    end

    it 'maps image to img' do
      expect(described_class.tag_for(:image)).to eq('img')
    end

    it 'defaults to div for unknown types' do
      expect(described_class.tag_for(:unknown_xyz)).to eq('div')
    end

    it 'is the single source of truth for Config.html_tag_for' do
      expect(described_class.tag_for(:paragraph)).to eq(Coradoc::Html::Config.html_tag_for(:paragraph))
      expect(described_class.tag_for(:bold)).to eq(Coradoc::Html::Config.html_tag_for(:bold))
      expect(described_class.tag_for(:source_code)).to eq(Coradoc::Html::Config.html_tag_for(:source_code))
    end
  end

  describe 'ELEMENT_TO_TAG completeness' do
    it 'includes all block-level types used by BlockDrop' do
      %i[paragraph source_code quote example sidebar literal listing open horizontal_rule].each do |type|
        expect(described_class::ELEMENT_TO_TAG).to have_key(type),
                                                   "TagMapping missing key: #{type}"
      end
    end

    it 'includes all inline types' do
      %i[bold italic monospace highlight superscript subscript underline strikethrough].each do |type|
        expect(described_class::ELEMENT_TO_TAG).to have_key(type),
                                                   "TagMapping missing key: #{type}"
      end
    end

    it 'includes all list types' do
      %i[ordered_list unordered_list list_item description_list description_term description_detail].each do |type|
        expect(described_class::ELEMENT_TO_TAG).to have_key(type),
                                                   "TagMapping missing key: #{type}"
      end
    end
  end
end
