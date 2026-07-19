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
          raise UnsupportedFormatError.new(format,
                                           available: FormatCatalog.registered_formats)
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

      def rewrite_links(document, rewriter: nil, &)
        Coradoc::LinkRewriter.rewrite(document, rewriter: rewriter, &)
      end

      # Resolve every reference (xref, citation, link, include, image,
      # footnote) in a parsed document using a unified content-graph
      # model. Mirrors +resolve_includes+ in shape: two-step, immutable.
      #
      # Step one always runs: every Edge is resolved through the
      # Resolver and the +missing+/+ambiguous+ policies are enforced
      # (raise or warn). Step two is opt-in: with +materialize: true+
      # the tree is rebuilt with each Edge replaced by the output of
      # the Materializer registered for its
      # [kind, presentation, format] tuple.
      #
      # The input document is never mutated. With +materialize: false+
      # the input document itself is returned; with +materialize: true+
      # a new document is returned that structurally shares untouched
      # subtrees with the input (treat both as immutable). Nodes whose
      # kind has no registered materializer are preserved unchanged.
      #
      # @param document [CoreModel::Base] parsed document
      # @param catalog [Reference::Catalog::*] index of addressable Content
      # @param presentation [Reference::Presentation::Base] slicing and ordering
      # @param resolver [Reference::Resolver::Base, nil] defaults to CatalogResolver
      # @param missing [Symbol] :warn (default), :silent, :error, :passthrough
      # @param ambiguous [Symbol] :disambiguate (default), :first, :error
      # @param materialize [Boolean] when true, replace edges with rendered inlines
      # @param format [Symbol, nil] target format for materializer lookup
      #   (:html, :asciidoc, ...); nil matches format-agnostic materializers
      # @return [CoreModel::Base] the input document (validation only) or
      #   a new materialized document
      #
      # @example Resolve cross-references into HTML links
      #   doc = Coradoc.parse(text, format: :asciidoc)
      #   catalog = Coradoc::Reference::Catalog::Local.from_doc(doc)
      #   presentation = Coradoc::Reference::Presentation::SingleDocument.new
      #   resolved = Coradoc.resolve_references(
      #     doc,
      #     catalog: catalog,
      #     presentation: presentation,
      #     materialize: true,
      #     format: :html
      #   )
      def resolve_references(document, catalog:, presentation:,
                             resolver: nil,
                             missing: :warn,
                             ambiguous: :disambiguate,
                             materialize: false,
                             format: nil)
        Coradoc::Reference::Resolution.new(
          catalog: catalog,
          presentation: presentation,
          resolver: resolver,
          missing: missing,
          ambiguous: ambiguous,
          materialize: materialize,
          format: format
        ).call(document)
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

      def serialize(model, to:, allow_unresolved_includes: false, **)
        format_module = FormatCatalog.get_format(to)
        raise UnsupportedFormatError.new(to, available: FormatCatalog.registered_formats) unless format_module

        Coradoc::Validation.guard_unresolved_includes!(model, format_module) unless allow_unresolved_includes

        model = Hooks.invoke(:before_serialize, model, format: to)
        result = format_module.serialize(model, **)
        Hooks.invoke(:after_serialize, result, format: to)
      end

      def build(&)
        CoreModel::DocumentElement.build(children: [], &)
      end

      def parse_file(path, format: nil)
        raise FileNotFoundError, path unless File.exist?(path)

        source_format = format || FormatCatalog.detect_format(path)
        raise UnsupportedFormatError, "Could not detect format for: #{path}" unless source_format

        format_module = FormatCatalog.get_format(source_format)
        unless format_module
          raise UnsupportedFormatError.new(source_format,
                                           available: FormatCatalog.registered_formats)
        end

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
