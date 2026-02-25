# frozen_string_literal: true

module Coradoc
  # Plugin discovery mechanism for auto-detecting and loading format gems.
  #
  # This module scans for installed gems that match the coradoc format gem
  # pattern (e.g., coradoc-html, coradoc-markdown) and auto-registers them
  # with the Coradoc registry.
  #
  # @example Auto-discover format gems
  #   Coradoc::PluginDiscovery.discover_and_register
  #
  # @example Check what gems were discovered
  #   discovered = Coradoc::PluginDiscovery.discover
  #   puts discovered.map(&:name)
  #
  # @example Disable auto-discovery
  #   Coradoc::PluginDiscovery.auto_discover = false
  #
  module PluginDiscovery
    # Pattern for matching coradoc format gems
    FORMAT_GEM_PATTERN = /\Acoradoc-(\w+)\z/

    # Known format gems in load order (dependencies first)
    KNOWN_FORMAT_GEMS = %w[
      coradoc-adoc
      coradoc-html
      coradoc-markdown
      coradoc-docx
    ].freeze

    class << self
      # Get or set auto-discover enabled state.
      #
      # @return [Boolean] true if auto-discover is enabled
      attr_accessor :auto_discover

      # Discover all installed coradoc format gems.
      #
      # @return [Array<Hash>] Array of discovered gem info with :name, :version, :path
      def discover
        discovered = []

        # Use Gem::Specification to find installed gems
        Gem::Specification.each do |spec|
          match = spec.name.match(FORMAT_GEM_PATTERN)
          next unless match

          format_name = match[1].to_sym
          discovered << {
            name: spec.name,
            format_name: format_name,
            version: spec.version.to_s,
            path: spec.gem_dir,
            loaded: gem_loaded?(spec.name)
          }
        end

        # Sort by known order, then alphabetically
        discovered.sort_by do |gem|
          idx = KNOWN_FORMAT_GEMS.index(gem[:name])
          idx.nil? ? Float::INFINITY : idx
        end
      end

      # Discover and register all format gems.
      #
      # @param force [Boolean] Force registration even if already registered
      # @return [Array<Symbol>] List of registered format names
      def discover_and_register(force: false)
        return [] unless auto_discover

        registered = []

        discover.each do |gem_info|
          next if gem_info[:loaded] && !force

          # Try to load and register the gem
          begin
            load_and_register(gem_info)
            registered << gem_info[:format_name]
          rescue LoadError => e
            Logger.warn("Failed to load format gem #{gem_info[:name]}: #{e.message}")
          rescue StandardError => e
            Logger.warn("Failed to register format gem #{gem_info[:name]}: #{e.message}")
          end
        end

        registered
      end

      # Check if a specific format gem is installed.
      #
      # @param format_name [Symbol, String] The format name (e.g., :html, :markdown)
      # @return [Boolean] true if the gem is installed
      def installed?(format_name)
        gem_name = "coradoc-#{format_name}"
        Gem::Specification.find_by_name(gem_name)
        true
      rescue Gem::MissingSpecError
        false
      end

      # Get the version of an installed format gem.
      #
      # @param format_name [Symbol, String] The format name
      # @return [String, nil] The version string, or nil if not installed
      def version(format_name)
        gem_name = "coradoc-#{format_name}"
        spec = Gem::Specification.find_by_name(gem_name)
        spec&.version&.to_s
      rescue Gem::MissingSpecError
        nil
      end

      # List all known format gem names.
      #
      # @return [Array<String>] List of known format gem names
      def known_format_gems
        KNOWN_FORMAT_GEMS.dup
      end

      private

      def gem_loaded?(gem_name)
        $LOADED_FEATURES.any? { |f| f.include?(gem_name) } ||
          defined?(Gem.loaded_specs) && Gem.loaded_specs.key?(gem_name)
      end

      def load_and_register(gem_info)
        gem_name = gem_info[:name]
        format_name = gem_info[:format_name]

        # Require the gem if not already loaded
        require gem_name unless gem_info[:loaded]

        # Get the format module
        format_module = find_format_module(format_name)
        return unless format_module

        # Register with Coradoc
        Coradoc.register_format(format_name, format_module)

        Logger.info("Auto-registered format: #{format_name}") if defined?(Logger)
      end

      def find_format_module(format_name)
        # Try common module name patterns
        module_candidates = [
          "Coradoc::#{format_name.to_s.capitalize}",
          "Coradoc::#{format_name.to_s.upcase}",
          "Coradoc::#{format_name}"
        ]

        module_candidates.each do |module_path|
          parts = module_path.split('::')
          mod = Object
          parts.each { |part| mod = mod.const_get(part) }
          return mod if mod.is_a?(Module)
        rescue NameError, TypeError
          next
        end

        nil
      end
    end

    # Enable auto-discover by default
    @auto_discover = true
  end
end
