# frozen_string_literal: true

require 'lutaml/model'

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
    # ---- Format registry (delegates to FormatCatalog) ----

    def registry = FormatCatalog.registry

    def register_format(format_name, format_module, **options)
      FormatCatalog.register_format(format_name, format_module, **options)
    end

    def get_format(format_name) = FormatCatalog.get_format(format_name)

    def registered_formats = FormatCatalog.registered_formats

    # ---- Pipeline (delegates to Pipeline) ----

    def parse(text, format:) = Pipeline.parse(text, format: format)

    def resolve_includes(document, **) = Pipeline.resolve_includes(document, **)

    def rewrite_links(...) = Pipeline.rewrite_links(...)

    def convert(text, **) = Pipeline.convert(text, **)

    def to_core(model) = Pipeline.to_core(model)

    def serialize(model, **) = Pipeline.serialize(model, **)

    def build(...) = Pipeline.build(...)

    def parse_file(path, **) = Pipeline.parse_file(path, **)

    def convert_file(path, **) = Pipeline.convert_file(path, **)

    # ---- Format detection (delegates to FormatCatalog) ----

    def detect_format(filename) = FormatCatalog.detect_format(filename)

    def binary_format?(format) = FormatCatalog.binary_format?(format)

    def normalize_format(name) = FormatCatalog.normalize_format(name)

    def serialize_format?(format) = FormatCatalog.serialize_format?(format)

    def parse_format?(format) = FormatCatalog.parse_format?(format)

    def format_capabilities = FormatCatalog.capabilities

    def resolve_output_format(output_file, **) = FormatCatalog.resolve_output_format(output_file, **)

    # ---- Introspection (delegates to Introspection) ----

    def file_info(path) = Introspection.file_info(path)

    def validate_file(path, **) = Introspection.validate_file(path, **)

    def document_stats(doc) = Introspection.document_stats(doc)

    def describe_element(elem) = Introspection.describe_element(elem)

    # ---- Utilities that stay on the top-level façade ----

    # Strip unicode whitespace from a string.
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

  autoload :Error, "#{__dir__}/errors"
  autoload :Version, "#{__dir__}/version"
  autoload :Logger, "#{__dir__}/logger"
  autoload :Hooks, "#{__dir__}/hooks"
  autoload :Query, "#{__dir__}/query"
  autoload :Validation, "#{__dir__}/validation"
  autoload :Configurable, "#{__dir__}/configurable"
  autoload :FormatModule, "#{__dir__}/format_module"
  autoload :CoreModel, "#{__dir__}/core_model"
  autoload :Registry, "#{__dir__}/registry"
  autoload :Visitor, "#{__dir__}/visitor"
  autoload :PerformanceRegression, "#{__dir__}/performance_regression"
  autoload :IncludeResolver, "#{__dir__}/include_resolver"
  autoload :IncludeSelectors, "#{__dir__}/include_selectors"
  autoload :ResolveIncludes, "#{__dir__}/resolve_includes"
  autoload :Pipeline, "#{__dir__}/pipeline"
  autoload :FormatCatalog, "#{__dir__}/format_catalog"
  autoload :Introspection, "#{__dir__}/introspection"
  autoload :Dispatch, "#{__dir__}/dispatch"
end

# Format gems self-register via Coradoc.register_format when they are required.
# No hardcoded registration needed here — each gem's entry file handles its own
# registration (e.g., coradoc-adoc/lib/coradoc/asciidoc.rb calls
# Coradoc.register_format(:asciidoc, Coradoc::AsciiDoc)).
