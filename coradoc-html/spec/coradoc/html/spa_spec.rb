# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Html::Spa do
  let(:document) { Coradoc::CoreModel::StructuralElement.new(element_type: 'document') }

  describe Coradoc::Html::Spa::Configuration do
    describe '.new' do
      it 'sets default values' do
        config = described_class.new

        expect(config.theme_variant).to eq(:glass)
        expect(config.primary_color).to eq('#6366f1')
        expect(config.accent_color).to eq('#8b5cf6')
        expect(config.theme_toggle).to be true
        expect(config.reading_progress).to be true
        expect(config.back_to_top).to be true
        expect(config.toc_sticky).to be true
        expect(config.copy_code_buttons).to be true
        expect(config.max_width).to eq('1200px')
        expect(config.content_width).to eq('65ch')
        expect(config.sidebar_width).to eq('280px')
        expect(config.lang).to eq('en')
      end

      it 'accepts custom values' do
        config = described_class.new(
          theme_variant: :minimal,
          primary_color: '#ff0000',
          accent_color: '#00ff00',
          theme_toggle: false,
          reading_progress: false
        )

        expect(config.theme_variant).to eq(:minimal)
        expect(config.primary_color).to eq('#ff0000')
        expect(config.accent_color).to eq('#00ff00')
        expect(config.theme_toggle).to be false
        expect(config.reading_progress).to be false
      end
    end

    describe '.defaults' do
      it 'returns a configuration with default values' do
        config = described_class.defaults

        expect(config).to be_a(described_class)
        expect(config.theme_variant).to eq(:glass)
        expect(config.primary_color).to eq('#6366f1')
      end
    end

    describe '#merge' do
      it 'merges with a hash' do
        config = described_class.new(theme_variant: :glass)
        merged = config.merge(theme_variant: :vibrant)

        expect(merged.theme_variant).to eq(:vibrant)
        expect(config.theme_variant).to eq(:glass) # Original unchanged
      end

      it 'merges with another configuration' do
        config1 = described_class.new(theme_variant: :glass)
        config2 = described_class.new(theme_variant: :minimal, primary_color: '#123456')
        merged = config1.merge(config2)

        expect(merged.theme_variant).to eq(:minimal)
        expect(merged.primary_color).to eq('#123456')
      end
    end

    describe '#to_h' do
      it 'returns a hash representation' do
        config = described_class.new(theme_variant: :minimal)
        hash = config.to_h

        expect(hash).to be_a(Hash)
        expect(hash[:theme_variant]).to eq(:minimal)
        expect(hash[:primary_color]).to eq('#6366f1')
      end
    end

    describe '#validate!' do
      it 'accepts valid theme variants' do
        %i[glass minimal vibrant].each do |variant|
          config = described_class.new(theme_variant: variant)
          expect { config.validate! }.not_to raise_error
        end
      end

      it 'rejects invalid theme variants' do
        config = described_class.new(theme_variant: :invalid)
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid theme variant/)
      end

      it 'accepts valid hex colors' do
        config = described_class.new(primary_color: '#6366f1', accent_color: '#8b5cf6')
        expect { config.validate! }.not_to raise_error

        config = described_class.new(primary_color: '#fff', accent_color: '#000')
        expect { config.validate! }.not_to raise_error
      end

      it 'rejects invalid hex colors' do
        config = described_class.new(primary_color: 'red')
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid hex color/)

        config = described_class.new(accent_color: 'xyz123')
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid hex color/)
      end

      it 'accepts valid CSS values' do
        config = described_class.new(max_width: '1200px', content_width: '65ch')
        expect { config.validate! }.not_to raise_error

        config = described_class.new(max_width: '100%', sidebar_width: '20rem')
        expect { config.validate! }.not_to raise_error
      end

      it 'rejects invalid CSS values' do
        config = described_class.new(max_width: 'invalid')
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid CSS value/)

        config = described_class.new(animation_duration: 'fast')
        expect do
          config.validate!
        end.to raise_error(Coradoc::Html::ConverterBase::ValidationError, /Invalid CSS value/)
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

    describe '#to_renderer_options' do
      it 'converts to renderer options format' do
        config = described_class.new(
          theme_variant: :glass,
          primary_color: '#6366f1',
          lang: 'en',
          toc_levels: 2
        )

        options = config.to_renderer_options

        expect(options).to be_a(Hash)
        expect(options[:modern]).to be_a(Hash)
        expect(options[:modern][:theme_variant]).to eq(:glass)
        expect(options[:lang]).to eq('en')
      end
    end
  end

  describe described_class do
    describe '.convert' do
      it 'converts a document to SPA HTML' do
        html = described_class.convert(document)

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('Vue') # Vue.js should be included
        expect(html).to include('tailwind') # Tailwind should be included
      end

      it 'accepts configuration as hash' do
        html = described_class.convert(document, theme_variant: 'minimal')

        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
      end

      it 'accepts configuration object' do
        config = Coradoc::Html::Spa::Configuration.new(theme_variant: :vibrant)
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
          expect(content).to include('Vue')
        end
      end
    end

    describe '#converter_name' do
      it 'returns :spa' do
        converter = described_class.new(document)
        expect(converter.converter_name).to eq(:spa)
      end
    end
  end
end
