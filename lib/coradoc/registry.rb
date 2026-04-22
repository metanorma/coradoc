# frozen_string_literal: true

module Coradoc
  # Registry for format-specific modules
  #
  # The Registry provides a central location for format gems to register
  # themselves. This enables the hub-and-spoke architecture where format
  # gems can discover each other through the registry.
  #
  # @example Registering a format
  #   Coradoc.registry.register(:asciidoc, Coradoc::AsciiDoc)
  #
  # @example Getting a registered format
  #   asciidoc = Coradoc.registry.get(:asciidoc)
  #
  # @example Listing all formats
  #   formats = Coradoc.registry.list
  #   # => [:asciidoc, :html, :markdown]
  class Registry
    # Initialize a new registry
    def initialize
      @formats = {}
      @options = {}
    end

    # Register a format module
    #
    # @param name [Symbol] the format name
    # @param format_module [Module] the format module
    # @param options [Hash] optional configuration (e.g., extensions: [])
    # @return [void]
    # @raise [ArgumentError] if name is not a Symbol
    def register(name, format_module, options = {})
      raise ArgumentError, "Format name must be a Symbol, got #{name.class}" unless name.is_a?(Symbol)

      @formats[name] = format_module
      @options[name] = options
    end

    # Get a registered format module
    #
    # @param name [Symbol] the format name
    # @return [Module, nil] the format module or nil if not found
    def get(name)
      @formats[name]
    end
    alias [] get

    # Get options for a registered format
    #
    # @param name [Symbol] the format name
    # @return [Hash, nil] the options hash or nil if not found
    def options_for(name)
      @options[name]
    end

    # Check if a format is registered
    #
    # @param name [Symbol] the format name
    # @return [Boolean] true if registered, false otherwise
    def registered?(name)
      @formats.key?(name)
    end

    # List all registered format names
    #
    # @return [Array<Symbol>] list of format names
    def list
      @formats.keys
    end

    # Get the number of registered formats
    #
    # @return [Integer] the count of registered formats
    def size
      @formats.size
    end

    # Clear all registered formats
    #
    # @return [void]
    def clear
      @formats.clear
      @options.clear
    end

    # Iterate over all registered formats
    #
    # @yield [Symbol, Module] the format name and module
    # @return [Enumerator] if no block given
    def each(&block)
      @formats.each(&block)
    end

    # Iterate over all registered format modules
    #
    # @yield [Module] the format module
    # @return [Enumerator] if no block given
    def each_value(&block)
      @formats.each_value(&block)
    end

    # Iterate over all registered format names
    #
    # @yield [Symbol] the format name
    # @return [Enumerator] if no block given
    def each_key(&block)
      @formats.each_key(&block)
    end
  end
end
