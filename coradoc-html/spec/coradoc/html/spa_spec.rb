# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Html::Spa do
  let(:document) { Coradoc::CoreModel::DocumentElement.new }

  describe Coradoc::Html::Spa::Configuration do
    describe '.new' do
      it 'sets default values' do
        config = described_class.new

        expect(config.theme_toggle).to be true
        expect(config.reading_progress).to be true
        expect(config.toc_sticky).to be true
        expect(config.toc_levels).to eq(2)
        expect(config.lang).to eq('en')
      end

      it 'accepts custom values' do
        config = described_class.new(
          theme_toggle: false,
          reading_progress: false,
          toc_sticky: false,
          toc_levels: 3
        )

        expect(config.theme_toggle).to be false
        expect(config.reading_progress).to be false
        expect(config.toc_sticky).to be false
        expect(config.toc_levels).to eq(3)
      end
    end

    describe '.defaults' do
      it 'returns a configuration with default values' do
        config = described_class.defaults

        expect(config).to be_a(described_class)
        expect(config.theme_toggle).to be true
        expect(config.toc_levels).to eq(2)
      end
    end

    describe '#merge' do
      it 'merges with a hash' do
        config = described_class.new(theme_toggle: true)
        merged = config.merge(theme_toggle: false)

        expect(merged.theme_toggle).to be false
        expect(config.theme_toggle).to be true
      end

      it 'merges with another configuration' do
        config1 = described_class.new(theme_toggle: true)
        config2 = described_class.new(theme_toggle: false, toc_levels: 4)
        merged = config1.merge(config2)

        expect(merged.theme_toggle).to be false
        expect(merged.toc_levels).to eq(4)
      end
    end

    describe '#to_h' do
      it 'returns a hash representation' do
        config = described_class.new(theme_toggle: false)
        hash = config.to_h

        expect(hash).to be_a(Hash)
        expect(hash[:theme_toggle]).to be false
      end
    end

    describe '#validate!' do
      it 'validates TOC levels' do
        config = described_class.new(toc_levels: 3)
        expect { config.validate! }.not_to raise_error

        config = described_class.new(toc_levels: 0)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /TOC levels/)

        config = described_class.new(toc_levels: 6)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /TOC levels/)
      end
    end
  end

  describe described_class, :requires_frontend_dist do
    describe '.convert' do
      it 'converts a document to SPA HTML' do
        html = described_class.convert(document)

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('CORADOC_DATA')
      end

      it 'accepts configuration as hash' do
        html = described_class.convert(document, toc_levels: 3)

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts configuration object' do
        config = Coradoc::Html::Spa::Configuration.new(toc_levels: 3)
        html = described_class.convert(document, config)

        expect(html).to be_a(String)
      end
    end

    describe '.to_file' do
      it 'writes SPA HTML to file' do
        Tempfile.create(['test', '.html']) do |file|
          path = file.path
          file.close

          described_class.to_file(document, path)

          content = File.read(path)
          expect(content).to include('<!DOCTYPE html>')
          expect(content).to include('CORADOC_DATA')
        end
      end
    end
  end
end
