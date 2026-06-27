# frozen_string_literal: true

module Coradoc
  # Parse / serialize / convert pipeline. Single source of truth for
  # the document transformation flow, extracted from the top-level
  # Coradoc façade so pipeline logic has its own home and its own
  # spec surface. Public API on +Coradoc+ delegates here.
  module Pipeline
    class << self
      # Parse text to a document model. Graph mode: +include::+
      # directives survive as +CoreModel::Include+ link nodes — no
      # file I/O happens during parse. Splicing included content is
      # a separate, explicit step (see +Coradoc.resolve_includes+).
      def parse(text, format:)
        format_module = FormatCatalog.get_format(format)
        unless format_module
          raise UnsupportedFormatError,
                "Format '#{format}' is not registered. " \
                "Available formats: #{FormatCatalog.registered_formats.join(', ')}"
        end

        text = Hooks.invoke(:before_parse, text, format: format)
        result = format_module.parse_to_core(text)
        Hooks.invoke(:after_parse, result, format: format)
      end

      def resolve_includes(document, base_dir:,
                           missing_include: :error,
                           max_depth: Coradoc::ResolveIncludes::DEFAULT_MAX_DEPTH,
                           allow_unsafe: false,
                           resolver: nil)
        resolver = Coradoc::IncludeResolver.coerce(
          resolver,
          base_dir: base_dir,
          allow_unsafe: allow_unsafe
        )
        Coradoc::ResolveIncludes.call(
          document,
          resolver: resolver,
          base_dir: base_dir,
          missing_include: missing_include,
          max_depth: max_depth
        )
      end

      def rewrite_links(document, rewriter: nil, &block)
        Coradoc::LinkRewriter.rewrite(document, rewriter: rewriter, &block)
      end

      def convert(text, from:, to:, **)
        core = parse(text, format: from)
        serialize(core, to: to, **)
      end

      def to_core(model)
        return model if model.is_a?(CoreModel::Base)

        FormatCatalog.registry.each_value do |format_module|
          next unless format_module.handles_model?(model)

          return format_module.to_core(model)
        end

        raise TransformationError, "No transformer found for #{model.class}"
      end

      def serialize(model, to:, **)
        format_module = FormatCatalog.get_format(to)
        raise UnsupportedFormatError, "Format '#{to}' is not registered" unless format_module

        model = Hooks.invoke(:before_serialize, model, format: to)
        result = format_module.serialize(model, **)
        Hooks.invoke(:after_serialize, result, format: to)
      end

      def build(&block)
        CoreModel::DocumentElement.build(children: [], &block)
      end

      def parse_file(path, format: nil)
        raise FileNotFoundError, path unless File.exist?(path)

        source_format = format || FormatCatalog.detect_format(path)
        raise UnsupportedFormatError, "Could not detect format for: #{path}" unless source_format

        format_module = FormatCatalog.get_format(source_format)
        raise UnsupportedFormatError, "Format '#{source_format}' is not registered" unless format_module

        if FormatCatalog.binary_format?(source_format)
          format_module.parse_to_core(path)
        else
          content = File.read(path)
          content = Hooks.invoke(:before_parse, content, format: source_format)
          result = format_module.parse_file_to_core(path, content)
          Hooks.invoke(:after_parse, result, format: source_format)
        end
      end

      def convert_file(path, to:, from: nil, **)
        source_format = from || FormatCatalog.detect_format(path)
        raise UnsupportedFormatError, "Could not detect format for: #{path}" unless source_format

        core = parse_file(path, format: source_format)
        serialize(core, to: to, **)
      end
    end
  end
end
