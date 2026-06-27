# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Coradoc::Html::InputConfig do
  let(:config) { described_class.new }

  describe '#with' do
    it 'yields with temporary options' do
      config.with(tag_border: '-') do
        expect(config.tag_border).to eq('-')
      end
      expect(config.tag_border).to eq(' ')
    end

    it 'restores previous options after nested with' do
      config.with(tag_border: '-') do
        config.with(tag_border: '=') do
          expect(config.tag_border).to eq('=')
        end
        expect(config.tag_border).to eq('-')
      end
      expect(config.tag_border).to eq(' ')
    end
  end

  describe 'default values' do
    it 'has :pass_through for unknown_tags' do
      expect(config.unknown_tags).to eq(:pass_through)
    end

    it 'has :html for input_format' do
      expect(config.input_format).to eq(:html)
    end

    it 'has false for mathml2asciimath' do
      expect(config.mathml2asciimath).to be false
    end

    it 'has false for external_images' do
      expect(config.external_images).to be false
    end

    it 'has 1 for image_counter' do
      expect(config.image_counter).to eq(1)
    end

    it 'has 1000 for doc_width' do
      expect(config.doc_width).to eq(1000)
    end

    it 'has empty plugins array' do
      expect(config.plugins).to eq([])
    end

    it 'has false for track_time' do
      expect(config.track_time).to be false
    end
  end

  describe 'option override via with' do
    it 'allows overriding unknown_tags' do
      config.with(unknown_tags: :drop) do
        expect(config.unknown_tags).to eq(:drop)
      end
    end

    it 'allows overriding external_images' do
      config.with(external_images: true) do
        expect(config.external_images).to be true
      end
    end
  end
end
