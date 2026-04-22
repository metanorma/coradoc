# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Coradoc::Configurable do
  describe Coradoc::Configurable::Configuration do
    let(:config) { described_class.new }

    describe '#initialize' do
      it 'creates configuration with defaults' do
        expect(config.environment).to eq('development')
        expect(config.cache).to be_a(Coradoc::Configurable::CacheConfig)
        expect(config.parser).to be_a(Coradoc::Configurable::ParserConfig)
        expect(config.transformer).to be_a(Coradoc::Configurable::TransformerConfig)
        expect(config.output).to be_a(Coradoc::Configurable::OutputConfig)
        expect(config.logging).to be_a(Coradoc::Configurable::LoggingConfig)
      end

      it 'accepts custom options' do
        config = described_class.new(
          environment: 'production',
          cache: { enabled: false, max_size: 500 }
        )
        expect(config.environment).to eq('production')
        expect(config.cache.enabled).to be false
        expect(config.cache.max_size).to eq(500)
      end
    end

    describe '#development?' do
      it 'returns true in development environment' do
        config.environment = 'development'
        expect(config).to be_development
      end

      it 'returns false in other environments' do
        config.environment = 'production'
        expect(config).not_to be_development
      end
    end

    describe '#production?' do
      it 'returns true in production environment' do
        config.environment = 'production'
        expect(config).to be_production
      end

      it 'returns false in other environments' do
        config.environment = 'development'
        expect(config).not_to be_production
      end
    end

    describe '#test?' do
      it 'returns true in test environment' do
        config.environment = 'test'
        expect(config).to be_test
      end

      it 'returns false in other environments' do
        config.environment = 'development'
        expect(config).not_to be_test
      end
    end

    describe '#[] and #[]=' do
      it 'gets and sets custom values' do
        config[:custom_key] = 'custom_value'
        expect(config[:custom_key]).to eq('custom_value')
      end

      it 'returns nil for missing keys' do
        expect(config[:missing_key]).to be_nil
      end
    end

    describe '#merge!' do
      it 'merges another configuration' do
        other = described_class.new(
          environment: 'production',
          cache: { max_size: 500 }
        )
        config.merge!(other)

        expect(config.environment).to eq('production')
        expect(config.cache.max_size).to eq(500)
      end

      it 'merges a hash' do
        config.merge!(
          environment: 'staging',
          custom: { key: 'value' }
        )

        expect(config.environment).to eq('staging')
        expect(config[:key]).to eq('value')
      end
    end

    describe '#dup' do
      it 'creates a copy of configuration' do
        copy = config.dup
        copy.environment = 'production'

        expect(config.environment).to eq('development')
        expect(copy.environment).to eq('production')
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        hash = config.to_h

        expect(hash).to have_key(:environment)
        expect(hash).to have_key(:cache)
        expect(hash).to have_key(:parser)
        expect(hash).to have_key(:transformer)
        expect(hash).to have_key(:output)
        expect(hash).to have_key(:logging)
        expect(hash).to have_key(:custom)
      end
    end

    describe '#reset!' do
      it 'resets to defaults' do
        config.environment = 'production'
        config.cache.enabled = false
        config.reset!

        expect(config.environment).to eq('development')
        expect(config.cache.enabled).to be true
      end
    end

    describe '#validate' do
      it 'returns empty array for valid config' do
        expect(config.validate).to eq([])
      end

      it 'returns errors for invalid cache.max_size' do
        config.cache.max_size = 0
        errors = config.validate
        expect(errors).to include('cache.max_size must be positive')
      end

      it 'returns errors for invalid cache.ttl' do
        config.cache.ttl = -1
        errors = config.validate
        expect(errors).to include('cache.ttl must be non-negative')
      end

      it 'returns errors for invalid cache.backend' do
        config.cache.backend = :invalid
        errors = config.validate
        expect(errors).to include('cache.backend must be :memory, :file, or :redis')
      end

      it 'returns errors for invalid logging.level' do
        config.logging.level = :invalid
        errors = config.validate
        expect(errors).to include('logging.level must be :debug, :info, :warn, or :error')
      end
    end

    describe '#valid?' do
      it 'returns true for valid config' do
        expect(config).to be_valid
      end

      it 'returns false for invalid config' do
        config.cache.max_size = 0
        expect(config).not_to be_valid
      end
    end

    describe '.load_file' do
      it 'loads configuration from YAML file' do
        yaml_content = <<~YAML
          environment: production
          cache:
            enabled: false
            max_size: 500
        YAML

        Tempfile.create(['coradoc_config', '.yml']) do |file|
          file.write(yaml_content)
          file.rewind

          config = described_class.load_file(file.path)
          expect(config.environment).to eq('production')
          expect(config.cache.enabled).to be false
          expect(config.cache.max_size).to eq(500)
        end
      end

      it 'raises error for missing file' do
        expect do
          described_class.load_file('/nonexistent/config.yml')
        end.to raise_error(Coradoc::Configurable::ConfigurationError, /not found/)
      end

      it 'raises error for invalid YAML' do
        Tempfile.create(['coradoc_config', '.yml']) do |file|
          file.write('invalid: yaml: content: [')
          file.rewind

          expect do
            described_class.load_file(file.path)
          end.to raise_error(Coradoc::Configurable::ConfigurationError, /Invalid YAML/)
        end
      end
    end

    describe '.load_environment' do
      it 'loads configuration from environment variables' do
        original = ENV.to_h

        begin
          ENV['CORADOC_ENV'] = 'test'
          ENV['CORADOC_CACHE_ENABLED'] = 'false'
          ENV['CORADOC_CACHE_MAX_SIZE'] = '2000'
          ENV['CORADOC_PARSER_STRICT_MODE'] = 'true'

          config = described_class.load_environment
          expect(config.environment).to eq('test')
          expect(config.cache.enabled).to be false
          expect(config.cache.max_size).to eq(2000)
          expect(config.parser.strict_mode).to be true
        ensure
          ENV.replace(original)
        end
      end
    end
  end

  describe Coradoc::Configurable::CacheConfig do
    describe '#initialize' do
      it 'sets defaults' do
        config = described_class.new
        expect(config.enabled).to be true
        expect(config.max_size).to eq(1000)
        expect(config.ttl).to eq(0)
        expect(config.backend).to eq(:memory)
        expect(config.cache_dir).to be_nil
      end

      it 'accepts custom options' do
        config = described_class.new(
          enabled: false,
          max_size: 500,
          ttl: 3600,
          backend: :file,
          cache_dir: '/tmp/cache'
        )
        expect(config.enabled).to be false
        expect(config.max_size).to eq(500)
        expect(config.ttl).to eq(3600)
        expect(config.backend).to eq(:file)
        expect(config.cache_dir).to eq('/tmp/cache')
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        config = described_class.new(enabled: false)
        hash = config.to_h
        expect(hash[:enabled]).to be false
      end
    end
  end

  describe Coradoc::Configurable::ParserConfig do
    describe '#initialize' do
      it 'sets defaults' do
        config = described_class.new
        expect(config.cache_enabled).to be true
        expect(config.strict_mode).to be false
        expect(config.include_source_loc).to be true
        expect(config.max_nesting_depth).to eq(100)
      end
    end
  end

  describe Coradoc::Configurable::TransformerConfig do
    describe '#initialize' do
      it 'sets defaults' do
        config = described_class.new
        expect(config.cache_enabled).to be true
        expect(config.preserve_unknown).to be true
        expect(config.validate_output).to be false
        expect(config.enabled_transformers).to eq([])
      end
    end
  end

  describe Coradoc::Configurable::OutputConfig do
    describe '#initialize' do
      it 'sets defaults' do
        config = described_class.new
        expect(config.default_format).to eq(:html)
        expect(config.pretty_print).to be true
        expect(config.line_width).to eq(80)
        expect(config.indent).to eq('  ')
        expect(config.include_metadata).to be false
      end
    end
  end

  describe Coradoc::Configurable::LoggingConfig do
    describe '#initialize' do
      it 'sets defaults' do
        config = described_class.new
        expect(config.level).to eq(:info)
        expect(config.timestamps).to be true
        expect(config.output).to eq($stderr)
        expect(config.colorize).to be true
      end
    end
  end

  describe 'module methods' do
    before do
      described_class.reset_configuration!
    end

    describe '.configuration' do
      it 'returns configuration instance' do
        expect(described_class.configuration).to be_a(Coradoc::Configurable::Configuration)
      end
    end

    describe '.configure' do
      it 'yields configuration' do
        described_class.configure do |config|
          config.environment = 'test'
        end
        expect(described_class.configuration.environment).to eq('test')
      end
    end

    describe '.reset_configuration!' do
      it 'resets to defaults' do
        described_class.configure { |c| c.environment = 'production' }
        described_class.reset_configuration!
        expect(described_class.configuration.environment).to eq('development')
      end
    end
  end

  describe 'Coradoc shortcuts' do
    before do
      described_class.reset_configuration!
    end

    describe '.config' do
      it 'returns configuration' do
        expect(Coradoc.config).to be_a(Coradoc::Configurable::Configuration)
      end
    end

    describe '.configure' do
      it 'configures Coradoc' do
        Coradoc.configure do |config|
          config.cache.enabled = false
        end
        expect(Coradoc.config.cache.enabled).to be false
      end
    end
  end
end
