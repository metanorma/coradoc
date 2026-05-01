# frozen_string_literal: true

module Coradoc
  # Shared registry for input/output processors.
  #
  # Both Input and Output modules use the same registration pattern:
  # define/get/registered?/for_file/process. This module extracts the
  # common logic to avoid duplication.
  #
  # @api private
  #
  # @example Including in a module
  #   module MyRegistry
  #     extend ProcessorRegistry
  #     self.error_label = "my processor"
  #   end
  module ProcessorRegistry
    # @return [String] label used in error messages
    attr_reader :error_label

    # Set the error label for "No ... processor found" messages
    # @param label [String]
    def error_label=(label)
      @error_label = label
    end

    # Get all registered processors
    # @return [Hash<Symbol, Module>]
    def processors
      @processors ||= {}
    end

    # Register a processor
    # @param processor [Module] Processor module to register
    # @return [void]
    def define(processor)
      return unless processor.respond_to?(:processor_id)

      processors[processor.processor_id] = processor
    end

    # Get a processor by ID
    # @param id [Symbol] Processor ID
    # @return [Module, nil]
    def get(id)
      processors[id.to_sym]
    end
    alias [] get

    # Check if a processor is registered
    # @param id [Symbol]
    # @return [Boolean]
    def registered?(id)
      processors.key?(id.to_sym)
    end

    # Find processor matching a filename
    # @param filename [String]
    # @return [Module, nil]
    def for_file(filename)
      processors.values.find do |processor|
        processor.respond_to?(:processor_match?) &&
          processor.processor_match?(filename)
      end
    end

    # Process with the appropriate processor
    # @param content [Object] Content to process
    # @param options [Hash]
    # @return [Object]
    def process(content, options = {})
      processor = if options[:format]
                    get(options[:format])
                  elsif options[:filename]
                    for_file(options[:filename])
                  end

      label = error_label || "processor"
      raise ArgumentError, "No #{label} found for: #{options}" unless processor

      processor.processor_execute(content, options)
    end
  end
end
