# frozen_string_literal: true

require_relative 'registry'

module Coradoc
  # Module adapter that gives a module Registry-backed processor methods.
  #
  # Both Input and Output extend this module to get processor registration,
  # lookup, and dispatch methods. All state is stored in a Registry instance.
  #
  # @api private
  #
  # @example
  #   module Input
  #     extend ProcessorRegistry
  #     self.error_label = "input processor"
  #   end
  module ProcessorRegistry
    def error_label=(label)
      @error_label = label
    end

    def registry
      @registry ||= Registry.new(error_label: @error_label)
    end

    def define(processor, **options)
      registry.define(processor, **options)
    end

    def get(id)
      registry.get(id)
    end
    alias [] get

    def registered?(id)
      registry.registered?(id)
    end

    def processors
      registry.items
    end

    def for_file(filename)
      registry.for_file(filename)
    end

    def process(content, options = {})
      registry.process(content, options)
    end
  end
end
