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
# @see Coradoc::CoreModel The canonical document model
# @see Coradoc::Hooks Plugin lifecycle hooks system
# @see Coradoc::FormatModule Interface contract for format modules
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
      FormatModule.validate!(format_module, format_name)
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

      text = Hooks.invoke(:before_parse, text, format: format)
      result = format_module.parse_to_core(text)
      Hooks.invoke(:after_parse, result, format: format)
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

      registry.each_value do |format_module|
        next unless format_module.respond_to?(:handles_model?) && format_module.handles_model?(model)

        return format_module.to_core(model)
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

      model = Hooks.invoke(:before_serialize, model, format: to)
      result = format_module.serialize(model, **options)
      Hooks.invoke(:after_serialize, result, format: to)
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
      DocumentManipulator.new(document)
    end

    # Detect format from a file extension
    #
    # @param filename [String] Filename or extension to detect
    # @return [Symbol, nil] the detected format symbol
    #
    # @example
    #   Coradoc.detect_format("document.adoc")  # => :asciidoc
    #   Coradoc.detect_format("file.md")        # => :markdown
    def detect_format(filename)
      ext = File.extname(filename).downcase
      registry.each do |name, _mod|
        opts = registry.options_for(name)
        return name if opts[:extensions]&.include?(ext)
      end
      nil
    end

    # Parse a document from a file path
    #
    # Handles both text formats (reads file content) and binary formats
    # (passes file path directly to the format module).
    #
    # @param path [String] path to the document file
    # @param format [Symbol, nil] source format (auto-detected if nil)
    # @return [Coradoc::CoreModel::Base] the parsed CoreModel document
    # @raise [UnsupportedFormatError] if format is not detected or registered
    #
    # @example
    #   doc = Coradoc.parse_file("document.adoc")
    #   doc = Coradoc.parse_file("report.docx", format: :docx)
    def parse_file(path, format: nil)
      raise FileNotFoundError, path unless File.exist?(path)

      source_format = format || detect_format(path)
      raise UnsupportedFormatError, "Could not detect format for: #{path}" unless source_format

      format_module = get_format(source_format)
      raise UnsupportedFormatError, "Format '#{source_format}' is not registered" unless format_module

      if binary_format?(source_format)
        format_module.parse_to_core(path)
      else
        content = File.read(path)
        parse(content, format: source_format)
      end
    end

    # Convert a file from one format to another
    #
    # @param path [String] path to the source document file
    # @param from [Symbol, nil] source format (auto-detected if nil)
    # @param to [Symbol] target format
    # @param options [Hash] additional options
    # @return [String] the converted document text
    #
    # @example
    #   html = Coradoc.convert_file("document.adoc", to: :html)
    #   adoc = Coradoc.convert_file("report.docx", to: :asciidoc)
    def convert_file(path, from: nil, to:, **options)
      source_format = from || detect_format(path)
      raise UnsupportedFormatError, "Could not detect format for: #{path}" unless source_format

      core = parse_file(path, format: source_format)
      serialize(core, to: to, **options)
    end

    # Check if a format requires binary (file path) input
    #
    # @param format [Symbol] the format to check
    # @return [Boolean] true if the format is binary
    def binary_format?(format)
      opts = registry.options_for(format)
      opts&.fetch(:binary, false) == true
    end

    # Normalize a format name string to a symbol
    #
    # Handles common aliases like "adoc" → :asciidoc, "md" → :markdown.
    #
    # @param name [String, Symbol, nil] the format name to normalize
    # @return [Symbol, nil] the normalized format symbol, or nil
    def normalize_format(name)
      return nil unless name

      key = name.to_s.downcase
      registry.each do |fmt_name, _mod|
        opts = registry.options_for(fmt_name)
        return fmt_name if opts[:aliases]&.include?(key)
      end
      key.to_sym
    end

    # Check if a format supports serialization (writing output)
    #
    # @param format [Symbol] the format to check
    # @return [Boolean] true if the format can serialize
    def serialize_format?(format)
      mod = get_format(format)
      return false unless mod

      return mod.serialize? if mod.respond_to?(:serialize?)

      true
    end

    # Check if a format supports parsing (reading input)
    #
    # @param format [Symbol] the format to check
    # @return [Boolean] true if the format can parse
    def parse_format?(format)
      mod = get_format(format)
      mod&.respond_to?(:parse_to_core) || mod&.respond_to?(:parse) || false
    end

    # Get capability summary for all registered formats
    #
    # Returns a hash mapping each format name to its capabilities
    # (parse: bool, serialize: bool). Useful for CLI display and introspection.
    #
    # @return [Hash<Symbol, Hash<Symbol, Boolean>>]
    def format_capabilities
      registered_formats.each_with_object({}) do |name, caps|
        caps[name] = {
          parse: parse_format?(name),
          serialize: serialize_format?(name)
        }
      end
    end

    # Resolve the output format from a filename, with a default
    #
    # @param output_file [String, nil] output filename to detect from
    # @param default [Symbol] default format when detection fails (default: :html)
    # @return [Symbol] the resolved format
    def resolve_output_format(output_file, default: :html)
      return default unless output_file

      detect_format(output_file) || default
    end

    # Get file metadata for display
    #
    # @param path [String] path to the file
    # @return [Hash] metadata including :size, :format, and :lines (for text formats)
    def file_info(path)
      fmt = detect_format(path)
      info = { size: File.size(path), format: fmt }
      info[:lines] = File.read(path).lines.count unless binary_format?(fmt)
      info
    end

    # Validate a document file
    #
    # Parses the file and validates against auto-generated schema.
    # Returns a Coradoc::Validation::Result.
    #
    # @param path [String] path to the document file
    # @param format [Symbol, nil] source format (auto-detected if nil)
    # @return [Coradoc::Validation::Result] validation result
    # @raise [UnsupportedFormatError] if format is not detected or registered
    def validate_file(path, format: nil)
      doc = parse_file(path, format: format)

      schema = Validation::SchemaGenerator.generate(doc.class)
      return schema.validate(doc) if schema

      Validation::Result.new
    end

    # Gather statistics about a parsed document
    #
    # @param doc [CoreModel::Base] parsed document
    # @return [Hash] statistics including element counts, title, etc.
    def document_stats(doc)
      stats = {}

      stats[:title] = doc.title if doc.respond_to?(:title) && doc.title

      if doc.respond_to?(:children)
        stats[:child_count] = count_elements(doc)
        stats[:element_counts] = count_element_types(doc)
      end

      stats
    end

    # Describe an element for display
    #
    # @param elem [Object] element to describe
    # @return [String] human-readable description
    def describe_element(elem)
      return elem.to_s unless elem.is_a?(CoreModel::Base)

      type = elem.class.name.split('::').last
      if elem.respond_to?(:title) && elem.title
        "#{type}: #{elem.title}"
      elsif elem.respond_to?(:content) && elem.content
        preview = elem.content.to_s[0..50]
        preview += '...' if elem.content.to_s.length > 50
        "#{type}: #{preview}"
      else
        type
      end
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

    private

    def count_elements(doc)
      return 0 unless doc.respond_to?(:children)

      doc.children.sum do |child|
        1 + (child.respond_to?(:children) ? count_elements(child) : 0)
      end
    end

    def count_element_types(doc)
      %w[section paragraph block list_block table image inline_element].each_with_object({}) do |type, counts|
        results = Query.query(doc, type)
        counts[type] = results.length if results.length.positive?
      end
    end
  end

  autoload :Version, "#{__dir__}/version"
  autoload :Logger, "#{__dir__}/logger"
  autoload :Hooks, "#{__dir__}/hooks"
  autoload :Query, "#{__dir__}/query"
  autoload :Validation, "#{__dir__}/validation"
  autoload :Configurable, "#{__dir__}/configurable"
  autoload :FormatModule, "#{__dir__}/format_module"
end

require_relative 'core_model'
require_relative 'registry'
require_relative 'transform'
require_relative 'input'
require_relative 'output'

# Format gems self-register via Coradoc.register_format when they are required.
# No hardcoded registration needed here — each gem's entry file handles its own
# registration (e.g., coradoc-adoc/lib/coradoc/asciidoc.rb calls
# Coradoc.register_format(:asciidoc, Coradoc::AsciiDoc)).
