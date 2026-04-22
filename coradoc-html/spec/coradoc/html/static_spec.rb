# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Html::Static do
  let(:document) { Coradoc::CoreModel::StructuralElement.new(element_type: 'document') }

  describe Coradoc::Html::Static::Configuration do
    describe '.new' do
      it 'sets default values' do
        config = described_class.new

        expect(config.css_theme).to eq(:professional)
        expect(config.asset_delivery).to eq(:embedded)
        expect(config.include_toc).to be false
        expect(config.theme_toggle).to be true
        expect(config.preserve_comments).to be false
        expect(config.lang).to eq('en')
      end

      it 'accepts custom values' do
        config = described_class.new(
          css_theme: :academic,
          asset_delivery: :external,
          include_toc: true,
          theme_toggle: false
        )

        expect(config.css_theme).to eq(:academic)
        expect(config.asset_delivery).to eq(:external)
        expect(config.include_toc).to be true
        expect(config.theme_toggle).to be false
      end
    end

    describe '.defaults' do
      it 'returns a configuration with default values' do
        config = described_class.defaults

        expect(config).to be_a(described_class)
        expect(config.css_theme).to eq(:professional)
      end
    end

    describe '#merge' do
      it 'merges with a hash' do
        config = described_class.new(css_theme: :professional)
        merged = config.merge(css_theme: :academic)

        expect(merged.css_theme).to eq(:academic)
        expect(config.css_theme).to eq(:professional) # Original unchanged
      end

      it 'merges with another configuration' do
        config1 = described_class.new(css_theme: :professional)
        config2 = described_class.new(css_theme: :academic, include_toc: true)
        merged = config1.merge(config2)

        expect(merged.css_theme).to eq(:academic)
        expect(merged.include_toc).to be true
      end
    end

    describe '#to_h' do
      it 'returns a hash representation' do
        config = described_class.new(css_theme: :academic)
        hash = config.to_h

        expect(hash).to be_a(Hash)
        expect(hash[:css_theme]).to eq(:academic)
      end
    end

    describe '#validate!' do
      it 'accepts valid CSS themes' do
        config = described_class.new(css_theme: :professional)
        expect { config.validate! }.not_to raise_error
      end

      it 'rejects invalid CSS themes' do
        config = described_class.new(css_theme: :invalid)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid CSS theme/)
      end

      it 'accepts valid asset delivery methods' do
        config = described_class.new(asset_delivery: :embedded)
        expect { config.validate! }.not_to raise_error

        config = described_class.new(asset_delivery: :external)
        expect { config.validate! }.not_to raise_error
      end

      it 'rejects invalid asset delivery methods' do
        config = described_class.new(asset_delivery: :invalid)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid asset delivery/)
      end

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

    describe '#embed_assets?' do
      it 'returns true when asset_delivery is :embedded' do
        config = described_class.new(asset_delivery: :embedded)
        expect(config.embed_assets?).to be true
      end

      it 'returns true when embedded mode is true' do
        config = described_class.new(embedded: true)
        expect(config.embed_assets?).to be true
      end

      it 'returns false when asset_delivery is :external' do
        config = described_class.new(asset_delivery: :external, embedded: false)
        expect(config.embed_assets?).to be false
      end
    end

    describe '#link_assets?' do
      it 'returns true when assets should be linked' do
        config = described_class.new(asset_delivery: :external, embedded: false)
        expect(config.link_assets?).to be true
      end

      it 'returns false when assets should be embedded' do
        config = described_class.new(asset_delivery: :embedded)
        expect(config.link_assets?).to be false
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
        html = described_class.convert(document, css_theme: 'academic')

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts configuration object' do
        config = Coradoc::Html::Static::Configuration.new(css_theme: :academic)
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

    describe '#converter_name' do
      it 'returns :static' do
        converter = described_class.new(document)
        expect(converter.converter_name).to eq(:static)
      end
    end
  end
end
