# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Audio do
  describe '.new' do
    it 'creates an audio element' do
      audio = described_class.new(
        id: 'audio-1',
        src: 'audio.mp3',
        title: 'Sample Audio'
      )

      expect(audio.id).to eq('audio-1')
      expect(audio.src).to eq('audio.mp3')
      expect(audio.title).to eq('Sample Audio')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      audio = described_class.new

      expect(audio).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Video do
  describe '.new' do
    it 'creates a video element with id' do
      video = described_class.new(id: 'video-1')

      expect(video.id).to eq('video-1')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      video = described_class.new(id: 'test')

      expect(video).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Bibliography do
  describe '.new' do
    it 'creates a bibliography section' do
      bib = described_class.new(
        id: 'bibliography'
      )

      expect(bib.id).to eq('bibliography')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      bib = described_class.new

      expect(bib).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::BibliographyEntry do
  describe '.new' do
    it 'creates a bibliography entry' do
      entry = described_class.new(
        id: 'ref-1'
      )

      expect(entry.id).to eq('ref-1')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      entry = described_class.new

      expect(entry).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end
