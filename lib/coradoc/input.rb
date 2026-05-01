# frozen_string_literal: true

require_relative 'processor_registry'

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
    extend ProcessorRegistry
    self.error_label = "input processor"
  end
end
