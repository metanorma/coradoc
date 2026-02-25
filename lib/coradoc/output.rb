# frozen_string_literal: true

module Coradoc
  # Output module for document serialization
  #
  # Provides a unified interface for document output processing.
  # Format-specific output processors register themselves with this module.
  #
  # @example Registering an output processor
  #   Coradoc::Output.define(MyHtmlProcessor)
  #
  # @example Using a registered processor
  #   processor = Coradoc::Output.get(:html_static)
  #   html = processor.processor_execute(document, {})
  #
  module Output
    class << self
      # Get all registered processors
      # @return [Hash<Symbol, Module>] Registered processors
      def processors
        @processors ||= {}
      end

      # Register an output processor
      # @param processor [Module] Processor module to register
      # @return [void]
      def define(processor)
        return unless processor.respond_to?(:processor_id)

        processors[processor.processor_id] = processor
      end

      # Get a processor by ID
      # @param id [Symbol] Processor ID
      # @return [Module, nil] Processor module or nil
      def get(id)
        processors[id.to_sym]
      end
      alias [] get

      # Check if a processor is registered
      # @param id [Symbol] Processor ID
      # @return [Boolean]
      def registered?(id)
        processors.key?(id.to_sym)
      end

      # Find processor that matches a filename
      # @param filename [String] Filename to match
      # @return [Module, nil] Matching processor or nil
      def for_file(filename)
        processors.values.find do |processor|
          processor.respond_to?(:processor_match?) &&
            processor.processor_match?(filename)
        end
      end

      # Process output with the appropriate processor
      # @param document [Object] Document to serialize
      # @param options [Hash] Processing options
      # @option options [Symbol] :format Output format (optional, auto-detected if not provided)
      # @option options [String] :filename Filename for format detection
      # @return [Object] Serialized output
      def process(document, options = {})
        processor = if options[:format]
                      get(options[:format])
                    elsif options[:filename]
                      for_file(options[:filename])
                    end

        raise ArgumentError, "No output processor found for: #{options}" unless processor

        processor.processor_execute(document, options)
      end
    end
  end
end
