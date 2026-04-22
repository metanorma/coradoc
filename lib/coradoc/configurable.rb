# frozen_string_literal: true

module Coradoc
  # Global configuration system for Coradoc.
  #
  # Provides centralized configuration management with support for:
  # - Configuration files (.coradoc.yml)
  # - Environment-specific settings
  # - Per-module configuration merging
  # - Validation of configuration values
  #
  # @example Basic configuration
  #   Coradoc.configure do |config|
  #     config.default_format = :asciidoc
  #     config.cache.enabled = true
  #     config.cache.max_size = 1000
  #   end
  #
  # @example Environment-specific configuration
  #   Coradoc.configure do |config|
  #     config.environment = ENV.fetch("RACK_ENV", "development")
  #     config.cache.enabled = config.production?
  #   end
  #
  # @example Loading from file
  #   Coradoc::Configuration.load_file(".coradoc.yml")
  #
  module Configurable
    # Configuration error
    class ConfigurationError < Coradoc::Error; end

    # Base class for configuration sections
    class ConfigSection
      # @return [Hash] Raw configuration values
      attr_reader :options

      # Create a configuration section
      #
      # @param options [Hash] Configuration options
      def initialize(options = {})
        @options = symbolize_keys(options)
        after_initialize if respond_to?(:after_initialize)
      end

      # Get a configuration value
      #
      # @param key [Symbol] Configuration key
      # @return [Object] Configuration value
      def [](key)
        @options[key]
      end

      # Set a configuration value
      #
      # @param key [Symbol] Configuration key
      # @param value [Object] Configuration value
      def []=(key, value)
        @options[key] = value
      end

      # Merge options into this section
      #
      # @param other [Hash, ConfigSection] Options to merge
      # @return [void]
      def merge!(other)
        other_options = other.is_a?(ConfigSection) ? other.options : other
        other_options = symbolize_keys(other_options)
        @options.merge!(other_options)
        # Apply merged options to accessors
        apply_options(other_options)
      end

      # Convert to hash
      #
      # @return [Hash]
      def to_h
        @options.transform_values do |v|
          v.is_a?(ConfigSection) ? v.to_h : v
        end
      end

      private

      def symbolize_keys(hash)
        return {} unless hash.is_a?(Hash)

        hash.transform_keys(&:to_sym)
      end

      # Apply options to instance variables
      # Override in subclasses for custom handling
      def apply_options(options)
        options.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
        end
      end
    end

    # Cache configuration section
    class CacheConfig < ConfigSection
      # @return [Boolean] Whether caching is enabled
      attr_accessor :enabled

      # @return [Integer] Maximum cache size (number of entries)
      attr_accessor :max_size

      # @return [Integer] Cache TTL in seconds (0 = no expiry)
      attr_accessor :ttl

      # @return [Symbol] Cache storage backend (:memory, :file, :redis)
      attr_accessor :backend

      # @return [String, nil] Cache directory for file backend
      attr_accessor :cache_dir

      def initialize(options = {})
        super
        @enabled = @options.fetch(:enabled, true)
        @max_size = @options.fetch(:max_size, 1000)
        @ttl = @options.fetch(:ttl, 0)
        @backend = @options.fetch(:backend, :memory)
        @cache_dir = @options.fetch(:cache_dir, nil)
      end
    end

    # Parser configuration section
    class ParserConfig < ConfigSection
      # @return [Boolean] Enable parser caching
      attr_accessor :cache_enabled

      # @return [Boolean] Strict parsing mode
      attr_accessor :strict_mode

      # @return [Boolean] Include source location in AST
      attr_accessor :include_source_loc

      # @return [Integer] Maximum nesting depth
      attr_accessor :max_nesting_depth

      def initialize(options = {})
        super
        @cache_enabled = @options.fetch(:cache_enabled, true)
        @strict_mode = @options.fetch(:strict_mode, false)
        @include_source_loc = @options.fetch(:include_source_loc, true)
        @max_nesting_depth = @options.fetch(:max_nesting_depth, 100)
      end
    end

    # Transformer configuration section
    class TransformerConfig < ConfigSection
      # @return [Boolean] Enable transformation caching
      attr_accessor :cache_enabled

      # @return [Boolean] Preserve unknown elements
      attr_accessor :preserve_unknown

      # @return [Boolean] Validate after transformation
      attr_accessor :validate_output

      # @return [Array<Symbol>] Enabled transformers
      attr_accessor :enabled_transformers

      def initialize(options = {})
        super
        @cache_enabled = @options.fetch(:cache_enabled, true)
        @preserve_unknown = @options.fetch(:preserve_unknown, true)
        @validate_output = @options.fetch(:validate_output, false)
        @enabled_transformers = @options.fetch(:enabled_transformers, [])
      end
    end

    # Output configuration section
    class OutputConfig < ConfigSection
      # @return [Symbol] Default output format
      attr_accessor :default_format

      # @return [Boolean] Pretty print output
      attr_accessor :pretty_print

      # @return [Integer] Line width for text output
      attr_accessor :line_width

      # @return [String] Indentation string
      attr_accessor :indent

      # @return [Boolean] Include metadata in output
      attr_accessor :include_metadata

      def initialize(options = {})
        super
        @default_format = @options.fetch(:default_format, :html)
        @pretty_print = @options.fetch(:pretty_print, true)
        @line_width = @options.fetch(:line_width, 80)
        @indent = @options.fetch(:indent, '  ')
        @include_metadata = @options.fetch(:include_metadata, false)
      end
    end

    # Logging configuration section
    class LoggingConfig < ConfigSection
      # @return [Symbol] Log level (:debug, :info, :warn, :error)
      attr_accessor :level

      # @return [Boolean] Include timestamps
      attr_accessor :timestamps

      # @return [IO, nil] Log output destination
      attr_accessor :output

      # @return [Boolean] Colorize output
      attr_accessor :colorize

      def initialize(options = {})
        super
        @level = @options.fetch(:level, :info)
        @timestamps = @options.fetch(:timestamps, true)
        @output = @options.fetch(:output, $stderr)
        @colorize = @options.fetch(:colorize, true)
      end
    end

    # Main configuration class
    class Configuration
      # @return [String] Current environment
      attr_accessor :environment

      # @return [CacheConfig] Cache configuration
      attr_reader :cache

      # @return [ParserConfig] Parser configuration
      attr_reader :parser

      # @return [TransformerConfig] Transformer configuration
      attr_reader :transformer

      # @return [OutputConfig] Output configuration
      attr_reader :output

      # @return [LoggingConfig] Logging configuration
      attr_reader :logging

      # @return [Hash] Custom configuration values
      attr_reader :custom

      # Create a new configuration
      #
      # @param options [Hash] Configuration options
      def initialize(options = {})
        options = symbolize_keys(options)
        @environment = options.fetch(:environment, detect_environment)
        @cache = CacheConfig.new(options[:cache] || {})
        @parser = ParserConfig.new(options[:parser] || {})
        @transformer = TransformerConfig.new(options[:transformer] || {})
        @output = OutputConfig.new(options[:output] || {})
        @logging = LoggingConfig.new(options[:logging] || {})
        @custom = options.fetch(:custom, {})
      end

      # Check if running in development environment
      #
      # @return [Boolean]
      def development?
        @environment == 'development'
      end

      # Check if running in production environment
      #
      # @return [Boolean]
      def production?
        @environment == 'production'
      end

      # Check if running in test environment
      #
      # @return [Boolean]
      def test?
        @environment == 'test'
      end

      # Get a custom configuration value
      #
      # @param key [Symbol] Configuration key
      # @return [Object] Configuration value
      def [](key)
        @custom[key.to_sym]
      end

      # Set a custom configuration value
      #
      # @param key [Symbol] Configuration key
      # @param value [Object] Configuration value
      def []=(key, value)
        @custom[key.to_sym] = value
      end

      # Merge another configuration into this one
      #
      # @param other [Configuration, Hash] Configuration to merge
      # @return [void]
      def merge!(other)
        case other
        when Configuration
          @environment = other.environment if other.environment != detect_environment
          @cache.merge!(other.cache)
          @parser.merge!(other.parser)
          @transformer.merge!(other.transformer)
          @output.merge!(other.output)
          @logging.merge!(other.logging)
          @custom.merge!(other.custom)
        when Hash
          merge_hash(other)
        end
      end

      # Create a copy of this configuration
      #
      # @return [Configuration]
      def dup
        self.class.new(to_h)
      end

      # Convert configuration to hash
      #
      # @return [Hash]
      def to_h
        {
          environment: @environment,
          cache: @cache.to_h,
          parser: @parser.to_h,
          transformer: @transformer.to_h,
          output: @output.to_h,
          logging: @logging.to_h,
          custom: @custom.dup
        }
      end

      # Load configuration from a YAML file
      #
      # @param path [String] Path to configuration file
      # @return [Configuration] Loaded configuration
      # @raise [ConfigurationError] If file cannot be loaded
      def self.load_file(path)
        require 'yaml'

        raise ConfigurationError, "Configuration file not found: #{path}" unless File.exist?(path)

        begin
          yaml_content = YAML.load_file(path)
          new(yaml_content || {})
        rescue Psych::SyntaxError => e
          raise ConfigurationError, "Invalid YAML in #{path}: #{e.message}"
        end
      end

      # Load configuration from environment variables
      #
      # @param prefix [String] Environment variable prefix
      # @return [Configuration] Configuration from environment
      def self.load_environment(prefix = 'CORADOC')
        options = {}

        # Parse CORADOC_CACHE_ENABLED=true style variables
        ENV.each do |key, value|
          next unless key.start_with?("#{prefix}_")

          # Convert CORADOC_CACHE_ENABLED to [:cache, :enabled]
          parts = key.sub("#{prefix}_", '').downcase.split('_')
          next if parts.length < 2

          section = parts.first.to_sym
          setting = parts[1..].join('_').to_sym

          options[section] ||= {}
          options[section][setting] = parse_env_value(value)
        end

        # Special handling for CORADOC_ENV
        options[:environment] = ENV["#{prefix}_ENV"] if ENV["#{prefix}_ENV"]

        new(options)
      end

      # Reset configuration to defaults
      #
      # @return [void]
      def reset!
        @environment = detect_environment
        @cache = CacheConfig.new
        @parser = ParserConfig.new
        @transformer = TransformerConfig.new
        @output = OutputConfig.new
        @logging = LoggingConfig.new
        @custom = {}
      end

      # Validate configuration
      #
      # @return [Array<String>] List of validation errors
      def validate
        errors = []

        errors << 'cache.max_size must be positive' if @cache.max_size <= 0
        errors << 'cache.ttl must be non-negative' if @cache.ttl.negative?
        errors << 'parser.max_nesting_depth must be positive' if @parser.max_nesting_depth <= 0
        errors << 'output.line_width must be positive' if @output.line_width <= 0

        errors << 'cache.backend must be :memory, :file, or :redis' unless %i[memory file
                                                                              redis].include?(@cache.backend)

        errors << 'logging.level must be :debug, :info, :warn, or :error' unless %i[debug info warn
                                                                                    error].include?(@logging.level)

        errors
      end

      # Check if configuration is valid
      #
      # @return [Boolean]
      def valid?
        validate.empty?
      end

      private

      def detect_environment
        ENV.fetch('RACK_ENV', ENV.fetch('RAILS_ENV', 'development'))
      end

      def symbolize_keys(hash)
        return {} unless hash.is_a?(Hash)

        hash.transform_keys(&:to_sym)
      end

      def merge_hash(hash)
        hash = symbolize_keys(hash)

        @environment = hash[:environment] if hash.key?(:environment)
        @cache.merge!(hash[:cache]) if hash.key?(:cache)
        @parser.merge!(hash[:parser]) if hash.key?(:parser)
        @transformer.merge!(hash[:transformer]) if hash.key?(:transformer)
        @output.merge!(hash[:output]) if hash.key?(:output)
        @logging.merge!(hash[:logging]) if hash.key?(:logging)
        @custom.merge!(symbolize_keys(hash[:custom] || {}))
      end

      def self.parse_env_value(value)
        case value.downcase
        when 'true', 'yes', '1'
          true
        when 'false', 'no', '0'
          false
        when /^\d+$/
          value.to_i
        when /^\d+\.\d+$/
          value.to_f
        else
          value
        end
      end
    end

    class << self
      # Get current global configuration
      #
      # @return [Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Set global configuration
      #
      # @param config [Configuration] Configuration to set
      # @return [void]
      attr_writer :configuration

      # Configure Coradoc
      #
      # @yield [Configuration] Block receives configuration object
      # @return [void]
      def configure
        yield configuration if block_given?
      end

      # Reset configuration to defaults
      #
      # @return [void]
      def reset_configuration!
        @configuration = Configuration.new
      end

      # Load configuration from file
      #
      # @param path [String] Path to configuration file
      # @return [void]
      def load_configuration(path)
        config = Configuration.load_file(path)
        configuration.merge!(config)
      end
    end
  end

  # Include Configurable in main module for easy access
  extend Configurable

  # Shortcut to configuration
  #
  # @return [Configuration]
  def self.config
    Configurable.configuration
  end

  # Shortcut to configure
  #
  # @yield [Configuration]
  # @return [void]
  def self.configure(&block)
    Configurable.configure(&block) if block_given?
  end
end
