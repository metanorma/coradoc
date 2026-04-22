# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Image do
  describe '.new' do
    it 'creates a block image' do
      image = described_class.new(
        src: 'images/diagram.png',
        alt: 'System Architecture',
        caption: 'Figure 1: System Overview'
      )

      expect(image.src).to eq('images/diagram.png')
      expect(image.alt).to eq('System Architecture')
      expect(image.caption).to eq('Figure 1: System Overview')
      expect(image.inline).to be false
    end

    it 'creates an inline image' do
      image = described_class.new(
        src: 'icons/warning.png',
        alt: 'Warning',
        inline: true
      )

      expect(image.inline).to be true
    end

    it 'creates an image with dimensions' do
      image = described_class.new(
        src: 'photo.jpg',
        width: '800px',
        height: '600px'
      )

      expect(image.width).to eq('800px')
      expect(image.height).to eq('600px')
    end

    it 'creates a linked image' do
      image = described_class.new(
        src: 'thumbnail.png',
        link: 'fullsize.png'
      )

      expect(image.link).to eq('fullsize.png')
    end
  end

  describe '#semantically_equivalent?' do
    let(:image1) do
      described_class.new(
        src: 'image.png',
        alt: 'Description'
      )
    end

    let(:image2) do
      described_class.new(
        src: 'image.png',
        alt: 'Description'
      )
    end

    let(:different_src) do
      described_class.new(
        src: 'other.png',
        alt: 'Description'
      )
    end

    let(:different_alt) do
      described_class.new(
        src: 'image.png',
        alt: 'Different'
      )
    end

    it 'returns true for identical images' do
      expect(image1.semantically_equivalent?(image2)).to be true
    end

    it 'returns false for images with different src' do
      expect(image1.semantically_equivalent?(different_src)).to be false
    end

    it 'returns false for images with different alt' do
      expect(image1.semantically_equivalent?(different_alt)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end
