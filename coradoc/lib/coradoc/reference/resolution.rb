# frozen_string_literal: true

module Coradoc
  module Reference
    # Orchestrator: resolves every Edge in the tree via the Resolver,
    # enforces the missing/ambiguous policies, and — only when asked
    # to materialize — rebuilds the tree with rendered inline nodes
    # via the Presentation layout and the Materializer registry.
    #
    # Two-step contract:
    # - +materialize: false+ validates references and returns the
    #   INPUT document (never mutated, never copied).
    # - +materialize: true+ returns a NEW document. Untouched subtrees
    #   are shared with the input (structural sharing) — treat both as
    #   immutable.
    #
    # Wired from the public API +Coradoc.resolve_references+.
    class Resolution
      attr_reader :catalog, :presentation, :resolver, :missing_policy,
                  :ambiguous_policy, :materialize_policy, :format,
                  :materializer_registry

      def initialize(catalog:, presentation:, missing:, ambiguous:,
                     materialize:, resolver: nil, format: nil,
                     materializer_registry: default_registry)
        @catalog = catalog
        @presentation = presentation
        @missing_policy = missing
        @ambiguous_policy = ambiguous
        @materialize_policy = materialize
        @format = format
        @materializer_registry = materializer_registry
        @resolver = resolver || Resolver::Catalog.new(
          catalog: catalog, ambiguous: ambiguous, missing: missing
        )
      end

      def call(document)
        results = resolve_all_edges(document)
        report_missing(results)
        return document unless materialize_policy

        materialize_tree(document, results)
      end

      private

      # Keyed by the Edge itself (value equality), so every distinct
      # edge gets its own Result while identical edges resolve once.
      def resolve_all_edges(document)
        results = {}
        EdgeSearch.each_edge(document) do |_parent, edge|
          results[edge] = resolver.resolve(edge)
        end
        results
      end

      def report_missing(results)
        results.each_value do |result|
          next unless result.missing?

          case missing_policy
          when :error
            raise Coradoc::Reference::MissingReferenceError.new(
              address: result.address
            )
          when :warn
            Coradoc::Logger.warn("Reference not found: #{result.address}")
          end
        end
      end

      def materialize_tree(document, results)
        pages = presentation.layout(document)
        ReplaceWalker.new(
          pages: pages,
          results: results,
          presentation: presentation,
          registry: materializer_registry,
          missing_policy: missing_policy,
          format: format
        ).visit(document)
      end

      def default_registry
        Materializer::Registry.new
      end

      # Rebuilds the tree, replacing every Edge-bearing node with the
      # materializer's output. The walker is single-purpose and only
      # lives inside Resolution — no need for a separate file.
      class ReplaceWalker
        attr_reader :pages, :results, :presentation, :registry,
                    :missing_policy, :format

        def initialize(pages:, results:, presentation:, registry:,
                       missing_policy:, format:)
          @pages = pages
          @results = results
          @presentation = presentation
          @registry = registry
          @missing_policy = missing_policy
          @format = format
        end

        def visit(node)
          return node unless node.is_a?(Coradoc::CoreModel::Base)

          replaced = replace_node(node)
          return replaced unless replaced.is_a?(Coradoc::CoreModel::HasChildren)

          rebuild_children_of(replaced)
        end

        private

        def replace_node(node)
          edges = EdgeSearch.edges_for(node)
          return node if edges.empty?

          materialize_edge(node, edges.first)
        end

        def materialize_edge(node, edge)
          result = results[edge]
          return drop_or_keep(node) if result.nil? || result.missing?

          invoke_materializer(node, edge, result)
        end

        # :silent drops the unresolved node; :warn (already logged) and
        # :passthrough keep the original node so round-tripping is safe.
        def drop_or_keep(node)
          return nil if missing_policy == :silent

          node
        end

        def invoke_materializer(node, edge, result)
          klass = lookup_materializer(edge)
          return node unless klass

          klass.new.materialize(
            edge: edge,
            result: result,
            node: node,
            presentation: presentation,
            pages: pages
          )
        end

        def lookup_materializer(edge)
          registry.lookup(
            kind: edge.kind.to_sym,
            presentation: presentation.key,
            format: format || :any
          )
        end

        def rebuild_children_of(node)
          children = node.children
          return node unless children
          return node if children.empty?

          new_children = children.filter_map { |c| visit(c) }
          rebuild_with(node, new_children)
        end

        def rebuild_with(node, new_children)
          return node if identical_children?(new_children, node.children)

          duplicate = node.dup
          duplicate.children = new_children
          duplicate
        end

        def identical_children?(new_children, old_children)
          new_children.length == old_children.length &&
            new_children.each_with_index.all? { |c, i| c.equal?(old_children[i]) }
        end
      end
    end
  end
end
