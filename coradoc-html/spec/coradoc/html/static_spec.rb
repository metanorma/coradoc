# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Html::Static do
  let(:document) { Coradoc::CoreModel::DocumentElement.new }

  describe Coradoc::Html::Static::Configuration do
    describe '.new' do
      it 'sets default values' do
        config = described_class.new

        expect(config.include_toc).to be false
        expect(config.toc_levels).to eq(2)
        expect(config.section_numbering).to be false
        expect(config.lang).to eq('en')
        expect(config.embedded).to be false
      end

      it 'accepts custom values' do
        config = described_class.new(
          include_toc: true,
          toc_levels: 3,
          section_numbering: true,
          lang: 'de'
        )

        expect(config.include_toc).to be true
        expect(config.toc_levels).to eq(3)
        expect(config.section_numbering).to be true
        expect(config.lang).to eq('de')
      end
    end

    describe '.defaults' do
      it 'returns a configuration with default values' do
        config = described_class.defaults

        expect(config).to be_a(described_class)
        expect(config.include_toc).to be false
      end
    end

    describe '#merge' do
      it 'merges with a hash' do
        config = described_class.new(include_toc: false)
        merged = config.merge(include_toc: true)

        expect(merged.include_toc).to be true
        expect(config.include_toc).to be false
      end

      it 'merges with another configuration' do
        config1 = described_class.new(include_toc: false)
        config2 = described_class.new(include_toc: true, toc_levels: 4)
        merged = config1.merge(config2)

        expect(merged.include_toc).to be true
        expect(merged.toc_levels).to eq(4)
      end
    end

    describe '#to_h' do
      it 'returns a hash representation' do
        config = described_class.new(include_toc: true)
        hash = config.to_h

        expect(hash).to be_a(Hash)
        expect(hash[:include_toc]).to be true
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

      it 'validates section numbering levels' do
        config = described_class.new(section_numbering_levels: 3)
        expect { config.validate! }.not_to raise_error

        config = described_class.new(section_numbering_levels: 0)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Section numbering levels/)

        config = described_class.new(section_numbering_levels: 7)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Section numbering levels/)
      end
    end
  end

  describe described_class do
    describe '.convert' do
      it 'converts a document to static HTML' do
        html = described_class.convert(document)

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('<html')
      end

      it 'accepts configuration as hash' do
        html = described_class.convert(document, lang: 'de')

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts configuration object' do
        config = Coradoc::Html::Static::Configuration.new(lang: 'de')
        html = described_class.convert(document, config)

        expect(html).to be_a(String)
      end
    end

    describe '.to_file' do
      it 'writes HTML to file' do
        Tempfile.create(['test', '.html']) do |file|
          path = file.path
          file.close

          described_class.to_file(document, path)

          content = File.read(path)
          expect(content).to include('<!DOCTYPE html>')
        end
      end
    end
  end
end
