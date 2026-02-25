# frozen_string_literal: true

require 'lutaml/model'
require_relative 'errors'

# Coradoc - A hub-and-spoke document transformation library
#
# Coradoc provides a unified document model (CoreModel) and transformation
# infrastructure for converting between document formats such as AsciiDoc,
# HTML, and Markdown.
#
# ## Architecture
#
# Coradoc uses a hub-and-spoke architecture where CoreModel acts as the
# canonical document representation. Each format (AsciiDoc, HTML, Markdown)
# has its own model and transformers to/from CoreModel.
#
# ```
# Source Format → Source Model → CoreModel → Target Model → Target Format
# ```
#
# ## Quick Start
#
# @example Parsing documents
#   require 'coradoc'
#
#   # Parse AsciiDoc to CoreModel
#   doc = Coradoc.parse("= Title\n\nContent", format: :asciidoc)
#
# @example Converting between formats
#   # Convert AsciiDoc to HTML
#   html = Coradoc.convert(adoc_text, from: :asciidoc, to: :html)
#
#   # Convert Markdown to AsciiDoc
#   adoc = Coradoc.convert(md_text, from: :markdown, to: :asciidoc)
#
# @example Using the hooks system
#   Coradoc::Hooks.register(:before_parse) do |content, format:|
#     puts "Parsing #{format} document..."
#     content
#   end
#
# @example Registering custom element types
#   Coradoc::Extensions.register_element(
#     :callout,
#     model_class: MyCalloutElement,
#     transformers: { html: MyCalloutHtmlTransformer }
#   )
#
# @see Coradoc::CoreModel The canonical document model
# @see Coradoc::Hooks Plugin lifecycle hooks system
# @see Coradoc::Extensions Custom element type registration
# @see Coradoc::PluginDiscovery Automatic format gem detection
#
module Coradoc
  # Base error class - defined in errors.rb
  # @see Coradoc::Error Base error class
  # @see Coradoc::ParseError Parsing errors with source context
  # @see Coradoc::ValidationError Document validation errors
  # @see Coradoc::TransformationError Model transformation errors
  # @see Coradoc::UnsupportedFormatError Unsupported format errors

  class << self
    # Get the format registry
    #
    # @return [Registry] the format registry
    def registry
      @registry ||= Registry.new
    end

    # Register a format gem
    #
    # @param format_name [Symbol] the format name (e.g., :asciidoc, :html, :markdown)
    # @param format_module [Module] the format module
    # @param options [Hash] optional configuration (e.g., extensions: [])
    # @return [void]
    def register_format(format_name, format_module, **options)
      registry.register(format_name, format_module, options)
    end

    # Get a registered format
    #
    # @param format_name [Symbol] the format name
    # @return [Module, nil] the format module or nil if not found
    def get_format(format_name)
      registry.get(format_name)
    end

    # List all registered formats
    #
    # @return [Array<Symbol>] list of registered format names
    def registered_formats
      registry.list
    end

    # Parse text to a document model
    #
    # This is the main entry point for parsing documents. It automatically
    # selects the appropriate parser based on the format.
    #
    # @param text [String] the document text to parse
    # @param format [Symbol] the source format (:asciidoc, :html, :markdown)
    # @return [Coradoc::CoreModel::Base, Object] the parsed document model
    # @raise [UnsupportedFormatError] if the format is not registered
    #
    # @example Parse AsciiDoc
    #   doc = Coradoc.parse("= Title\n\nContent", format: :asciidoc)
    #   doc = Coradoc.parse(File.read("doc.adoc"), format: :asciidoc)
    #
    # @example Parse and get CoreModel
    #   core = Coradoc.parse(text, format: :asciidoc)  # Returns CoreModel
    def parse(text, format:)
      format_module = get_format(format)
      unless format_module
        raise UnsupportedFormatError,
              "Format '#{format}' is not registered. " \
              "Available formats: #{registered_formats.join(', ')}"
      end

      # Check if format module responds to parse_to_core (preferred)
      if format_module.respond_to?(:parse_to_core)
        format_module.parse_to_core(text)
      elsif format_module.respond_to?(:parse)
        # Fall back to parse method, then transform to CoreModel
        doc = format_module.parse(text)
        to_core(doc)
      else
        raise UnsupportedFormatError,
              "Format module #{format_module} does not implement parse or parse_to_core"
      end
    end

    # Convert document text from one format to another
    #
    # This is the main entry point for format conversion. It handles the
    # complete pipeline: parse -> transform to CoreModel -> transform to target -> serialize
    #
    # @param text [String] the source document text
    # @param from [Symbol] the source format (:asciidoc, :html, :markdown)
    # @param to [Symbol] the target format (:asciidoc, :html, :markdown)
    # @param options [Hash] additional options for the conversion
    # @return [String] the converted document text
    # @raise [UnsupportedFormatError] if a format is not registered
    #
    # @example Convert AsciiDoc to HTML
    #   html = Coradoc.convert(adoc_text, from: :asciidoc, to: :html)
    #
    # @example Convert HTML to AsciiDoc
    #   adoc = Coradoc.convert(html_text, from: :html, to: :asciidoc)
    def convert(text, from:, to:, **options)
      # Parse to CoreModel
      core = parse(text, format: from)

      # Convert to target format
      serialize(core, to: to, **options)
    end

    # Transform a model to CoreModel
    #
    # @param model [Object] a format-specific model
    # @return [Coradoc::CoreModel::Base] the CoreModel representation
    def to_core(model)
      return model if model.is_a?(CoreModel::Base)

      # Check if model is an AsciiDoc model
      if defined?(Coradoc::AsciiDoc::Model::Base) && model.is_a?(Coradoc::AsciiDoc::Model::Base)
        return Coradoc::AsciiDoc::Transform::ToCoreModel.transform(model)
      end

      # Try to find a transformer via registered formats
      registry.each_value do |format_module|
        next unless format_module.respond_to?(:to_core)

        result = format_module.to_core(model)
        return result if result
      end

      raise TransformationError, "No transformer found for #{model.class}"
    end

    # Serialize a CoreModel to a specific format
    #
    # @param model [Coradoc::CoreModel::Base] the CoreModel to serialize
    # @param to [Symbol] the target format
    # @param options [Hash] additional options
    # @return [String] the serialized document
    def serialize(model, to:, **options)
      format_module = get_format(to)
      raise UnsupportedFormatError, "Format '#{to}' is not registered" unless format_module

      # Check if format module has serialize method
      unless format_module.respond_to?(:serialize)
        raise UnsupportedFormatError,
              "Format module #{format_module} does not implement serialize"
      end

      format_module.serialize(model, **options)
    end

    # Create a DocumentManipulator for chainable operations
    #
    # @param document [Coradoc::CoreModel::Base] the document to manipulate
    # @return [DocumentManipulator] a new manipulator instance
    #
    # @example Chainable document manipulation
    #   html = Coradoc.manipulate(doc)
    #     .transform_text(&:upcase)
    #     .add_toc
    #     .to_html
    def manipulate(document)
      require_relative 'document_manipulator'
      DocumentManipulator.new(document)
    end

    # Strip unicode whitespace from a string
    #
    # @param string [String] the string to strip
    # @param only [Symbol, nil] what to strip: :begin, :end, or nil for both
    # @return [String] the stripped string
    def strip_unicode(string, only: nil)
      return string if string.nil?

      case only
      when :begin
        string.sub(/^\p{Zs}+/, '')
      when :end
        string.sub(/\p{Zs}+$/, '')
      else
        string.sub(/^\p{Zs}+/, '').sub(/\p{Zs}+$/, '')
      end
    end
  end
end

require_relative 'version'
require_relative 'logger'
require_relative 'hooks'
require_relative 'plugin_discovery'
require_relative 'extensions'
require_relative 'performance_regression'
require_relative 'query'
require_relative 'validation'
require_relative 'streaming'
require_relative 'memory'
require_relative 'lazy'
require_relative 'configurable'
require_relative 'transformation_cache'
require_relative 'normalize'
require_relative 'core_model'
require_relative 'registry'
require_relative 'transform'
require_relative 'transform/asciidoc_to_core_model'
require_relative 'input'
require_relative 'output'

# Auto-register any format modules that were loaded before coradoc
# This handles the case where format gems are required before the core gem
if defined?(Coradoc::AsciiDoc) && !Coradoc.registered_formats.include?(:asciidoc)
  Coradoc.register_format(:asciidoc,
                          Coradoc::AsciiDoc)
end
Coradoc.register_format(:html, Coradoc::Html) if defined?(Coradoc::Html) && !Coradoc.registered_formats.include?(:html)
if defined?(Coradoc::Markdown) && !Coradoc.registered_formats.include?(:markdown)
  Coradoc.register_format(:markdown,
                          Coradoc::Markdown)
end
Coradoc.register_format(:docx, Coradoc::Docx) if defined?(Coradoc::Docx) && !Coradoc.registered_formats.include?(:docx)
