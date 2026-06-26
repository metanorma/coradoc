# frozen_string_literal: true

module Coradoc
  module Reference
    # Orchestrator: walks the tree, resolves every Edge via the
    # Resolver, layouts the resolved graph via the Presentation, and
    # optionally materializes Edges into rendered inline nodes.
    #
    # Returns a NEW document — the input is never mutated.
    #
    # Wired from the public API +Coradoc.resolve_references+.
    class Resolution
      attr_reader :catalog, :presentation, :resolver, :missing_policy,
                  :ambiguous_policy, :materialize_policy, :materializer_registry

      def initialize(catalog:, presentation:, resolver:, # rubocop:disable Metrics/ParameterLists
                     missing:, ambiguous:, materialize:,
                     materializer_registry: default_registry)
        @catalog = catalog
        @presentation = presentation
        @resolver = resolver
        @missing_policy = missing
        @ambiguous_policy = ambiguous
        @materialize_policy = materialize
        @materializer_registry = materializer_registry
      end

      def call(document)
        resolved = resolve_tree(document)
        return resolved unless materialize_policy

        materialize_tree(resolved)
      end

      private

      def resolve_tree(node)
        return node unless node.is_a?(Coradoc::CoreModel::Base)

        rebuild_children(node)
      end

      def rebuild_children(node)
        return node unless node.is_a?(Coradoc::CoreModel::HasChildren)

        children = node.children
        return node unless children
        return node if children.empty?

        rebuild_with(node, children.map { |child| resolve_tree(child) })
      end

      def materialize_tree(document)
        pages = presentation.layout(document)
        result_map = resolve_all_edges(document)
        replace_edges(document, pages: pages, results: result_map)
      end

      def resolve_all_edges(document)
        results = {}
        EdgeSearch.each_edge(document) do |_parent, edge|
          results[edge.address] = resolver.resolve(edge)
        end
        results
      end

      def replace_edges(document, pages:, results:)
        walker = ReplaceWalker.new(
          pages: pages,
          results: results,
          presentation: presentation,
          registry: materializer_registry,
          missing_policy: missing_policy
        )
        walker.visit(document)
      end

      def rebuild_with(node, new_children)
        return node if identical_children?(new_children, node.children)

        duplicate = node.dup
        duplicate.children = new_children
        duplicate
      end

      def identical_children?(new_children, old_children)
        new_children.each_with_index.all? { |c, i| c.equal?(old_children[i]) }
      end

      def default_registry
        Materializer::Registry.new
      end

      # Rebuilds the tree, replacing every Edge-bearing node with the
      # materializer's output. The walker is single-purpose and only
      # lives inside Resolution — no need for a separate file.
      class ReplaceWalker
        attr_reader :pages, :results, :presentation, :registry, :missing_policy

        def initialize(pages:, results:, presentation:, registry:, missing_policy:)
          @pages = pages
          @results = results
          @presentation = presentation
          @registry = registry
          @missing_policy = missing_policy
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
          result = results[edge.address]
          return passthrough_or_drop(node, edge) if result.nil? || result.missing?

          invoke_materializer(node, edge, result)
        end

        def passthrough_or_drop(node, edge)
          return nil if missing_policy == :silent

          missing = Coradoc::Reference::Result::Missing.build(
            edge: edge, address: edge.address
          )
          invoke_materializer(node, edge, missing)
        end

        def invoke_materializer(node, edge, result)
          klass = lookup_materializer(edge)
          return node unless klass

          klass.new.materialize(
            edge: edge,
            result: result,
            presentation: presentation,
            pages: pages
          )
        end

        def lookup_materializer(edge)
          registry.lookup(
            kind: edge.kind.to_sym,
            presentation: :any,
            format: :html
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
          new_children.each_with_index.all? { |c, i| c.equal?(old_children[i]) }
        end
      end
    end
  end
end
