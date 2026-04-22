# frozen_string_literal: true

module Coradoc
  # Input module for document ingestion
  #
  # Provides a unified interface for document input processing.
  # Format-specific input processors register themselves with this module.
  #
  # @example Registering an input processor
  #   Coradoc::Input.define(MyHtmlProcessor)
  #
  # @example Using a registered processor
  #   processor = Coradoc::Input.for(:html)
  #   document = processor.convert(html_content)
  #
  module Input
    class << self
      # Get all registered processors
      # @return [Hash<Symbol, Module>] Registered processors
      def processors
        @processors ||= {}
      end

      # Register an input processor
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

      # Process input with the appropriate processor
      # @param input [String] Input content
      # @param options [Hash] Processing options
      # @option options [Symbol] :format Input format (optional, auto-detected if not provided)
      # @option options [String] :filename Filename for format detection
      # @return [Object] Processed document
      def process(input, options = {})
        processor = if options[:format]
                      get(options[:format])
                    elsif options[:filename]
                      for_file(options[:filename])
                    end

        raise ArgumentError, "No input processor found for: #{options}" unless processor

        processor.processor_execute(input, options)
      end
    end
  end
end
