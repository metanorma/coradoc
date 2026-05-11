# frozen_string_literal: true

require_relative 'processor_registry'

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
    extend ProcessorRegistry
    self.error_label = 'output processor'
  end
end
