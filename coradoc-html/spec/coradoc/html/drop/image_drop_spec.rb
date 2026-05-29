# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/image_drop'

RSpec.describe Coradoc::Html::Drop::ImageDrop do
  let(:model) { CoreModel::Image.new(src: 'photo.png', alt: 'A photo') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#src' do
    it 'returns the image source' do
      expect(drop.src).to eq('photo.png')
    end
  end

  describe '#alt' do
    it 'returns the alt text' do
      expect(drop.alt).to eq('A photo')
    end
  end

  describe '#inline?' do
    it 'returns false for block image by default' do
      expect(drop.inline?).to be false
    end

    it 'returns true for inline image' do
      img = CoreModel::Image.new(src: 'icon.png', inline: true)
      expect(described_class.new(img).inline?).to be true
    end
  end

  describe '#caption' do
    it 'returns escaped caption' do
      img = CoreModel::Image.new(src: 'fig.png', caption: 'Figure 1')
      expect(described_class.new(img).caption).to eq('Figure 1')
    end

    it 'returns nil without caption' do
      expect(drop.caption).to be_nil
    end
  end

  describe '#id' do
    it 'returns the model id' do
      img = CoreModel::Image.new(src: 'fig.png', id: 'fig1')
      expect(described_class.new(img).id).to eq('fig1')
    end
  end

  describe '#width' do
    it 'returns the width' do
      img = CoreModel::Image.new(src: 'fig.png', width: '200')
      expect(described_class.new(img).width).to eq('200')
    end
  end

  describe '#height' do
    it 'returns the height' do
      img = CoreModel::Image.new(src: 'fig.png', height: '150')
      expect(described_class.new(img).height).to eq('150')
    end
  end
end
