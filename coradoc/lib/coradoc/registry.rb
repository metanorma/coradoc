# frozen_string_literal: true

module Coradoc
  # General-purpose named-item registry.
  #
  # Used by the format registry (Coradoc.registry), Input processors,
  # and Output processors. Each instance stores items keyed by symbol
  # name, with optional per-item options.
  #
  # @example Format registry
  #   registry = Registry.new
  #   registry.register(:html, Coradoc::Html)
  #   registry.get(:html)  # => Coradoc::Html
  #
  # @example Processor registry (self-identifying items)
  #   registry = Registry.new(error_label: "input processor")
  #   registry.define(MyProcessor)  # uses MyProcessor.processor_id
  #   registry.for_file("doc.html") # checks processor_match? on each item
  #
  class Registry
    attr_reader :error_label

    # @param error_label [String, nil] label for error messages in #process
    def initialize(error_label: nil)
      @items = {}
      @options = {}
      @error_label = error_label
    end

    # Register an item by explicit name
    #
    # @param name [Symbol] the item name
    # @param item [Object] the item to register
    # @param opts [Hash] optional per-item configuration
    # @raise [ArgumentError] if name is not a Symbol
    def register(name, item, opts = {})
      raise ArgumentError, "Name must be a Symbol, got #{name.class}" unless name.is_a?(Symbol)

      @items[name] = item
      @options[name] = opts
    end

    # Register a self-identifying item (extracts name via processor_id)
    #
    # @param item [Object] item that responds to #processor_id
    # @param options [Hash] optional per-item configuration
    # @return [void]
    def define(item, **opts)
      register(item.processor_id, item, opts)
    end

    # Get a registered item by name
    #
    # @param name [Symbol, String] the item name (strings are coerced to symbols)
    # @return [Object, nil]
    def get(name)
      @items[name.to_sym]
    end
    alias [] get

    # Get options for a registered item
    #
    # @param name [Symbol]
    # @return [Hash, nil]
    def options_for(name)
      @options[name]
    end

    # Check if an item is registered
    #
    # @param name [Symbol]
    # @return [Boolean]
    def registered?(name)
      @items.key?(name)
    end

    # List all registered item names
    #
    # @return [Array<Symbol>]
    def list
      @items.keys
    end

    # Direct access to the items hash (for backward compatibility)
    # @return [Hash<Symbol, Object>]
    attr_reader :items

    # Number of registered items
    #
    # @return [Integer]
    def size
      @items.size
    end

    # Remove all registered items
    def clear
      @items.clear
      @options.clear
    end

    # Iterate over all items
    #
    # @yield [Symbol, Object] name and item
    # @return [Enumerator]
    def each(&block)
      @items.each(&block)
    end

    # Iterate over item values
    #
    # @yield [Object]
    # @return [Enumerator]
    def each_value(&block)
      @items.each_value(&block)
    end

    # Iterate over item names
    #
    # @yield [Symbol]
    # @return [Enumerator]
    def each_key(&block)
      @items.each_key(&block)
    end

    # Find an item whose processor_match? returns true for the given filename
    #
    # @param filename [String]
    # @return [Object, nil]
    def for_file(filename)
      @items.values.find do |item|
        item.processor_match?(filename)
      rescue NoMethodError
        false
      end
    end

    # Resolve and execute: find item by format or filename, call processor_execute
    #
    # @param content [Object] content to process
    # @param options [Hash] :format or :filename for resolution
    # @return [Object] result of processor_execute
    # @raise [ArgumentError] if no matching item found
    def process(content, options = {})
      item = if options[:format]
               get(options[:format])
             elsif options[:filename]
               for_file(options[:filename])
             end

      label = @error_label || 'processor'
      raise ArgumentError, "No #{label} found for: #{options}" unless item

      item.processor_execute(content, options)
    end
  end
end
