# frozen_string_literal: true

module Coradoc
  module Reference
    # Walks a CoreModel tree and yields every Edge found in it. For
    # Phase 1, Edges are wrapped inside existing node types —
    # +CrossReferenceElement+, +LinkElement+, +Image+, +Include+,
    # +FootnoteElement+. The Phase 3 migration will move Edges to
    # first-class attributes; this module abstracts the extraction so
    # the rest of the resolver doesn't change.
    #
    # The walker is read-only: it never mutates the input tree.
    module EdgeSearch
      module_function

      # Yields (parent_node, edge) for every Edge found in the tree.
      # The parent_node is the node that owns the edge — the
      # materializer replaces the edge in-place inside parent_node's
      # children list.
      def each_edge(root)
        return to_enum(:each_edge, root) unless block_given?

        walk(root) { |node| edges_for(node).each { |edge| yield node, edge } }
      end

      # Walk tree, yield each Base node. Stops at inline leaves.
      def walk(node, &block)
        return unless node.is_a?(Coradoc::CoreModel::Base)
        return unless block

        yield(node)
        return unless node.is_a?(Coradoc::CoreModel::HasChildren)

        children = node.children
        return unless children

        children.each { |child| walk(child, &block) }
      end

      # Extract every Edge the given node owns. Pure function of node.
      def edges_for(node)
        edge_extractor = EDGE_EXTRACTORS[node.class]
        return [] unless edge_extractor

        edge = edge_extractor.call(node)
        edge ? [edge] : []
      end

      def edge_from_cross_reference(node)
        Edge.build(
          kind: :navigation,
          address: parse_address(node.target, hint: xref_hint(node.target)),
          source_id: node.id,
          label: node.content
        )
      end

      def edge_from_link(node)
        Edge.build(
          kind: :link,
          address: parse_address(node.target),
          source_id: node.id,
          label: node.content
        )
      end

      def edge_from_include(node)
        Edge.build(
          kind: :include,
          address: parse_address(node.target, hint: path_or_url_hint(node.target)),
          source_id: node.id,
          options: { include_options: node.options }
        )
      end

      def edge_from_image(node)
        Edge.build(
          kind: :image_ref,
          address: parse_address(node.src, hint: path_or_url_hint(node.src)),
          source_id: node.id,
          label: node.alt,
          options: { alt_text: node.alt }
        )
      end

      def edge_from_footnote(node)
        Edge.build(
          kind: :footnote_ref,
          address: parse_address(node.target || node.id, hint: :anchor),
          source_id: node.id,
          options: { footnote_id: node.id }
        )
      end

      # Xrefs are document-internal by definition (AsciiDoc): bare
      # targets are anchors, even uppercase document-ID-shaped ones
      # ("SEC-2"). Only an explicit "document#fragment" shape or a URL
      # points outside the current document.
      def xref_hint(target)
        raw = target.to_s
        return :url if Coradoc::Reference::Address::Url.matches?(raw)
        return :path if raw.include?('#') && !raw.start_with?('#')

        :anchor
      end

      # File-like targets (include, image): URLs stay urls, everything
      # else is a path — including bare filenames ("foo.png") that the
      # anchor bareword heuristic would otherwise claim.
      def path_or_url_hint(target)
        Coradoc::Reference::Address::Url.matches?(target.to_s) ? :url : :path
      end

      def parse_address(target, hint: nil)
        Coradoc::Reference::Address.parse(target.to_s, hint: hint)
      end

      EDGE_EXTRACTORS = {
        Coradoc::CoreModel::CrossReferenceElement => method(:edge_from_cross_reference),
        Coradoc::CoreModel::LinkElement => method(:edge_from_link),
        Coradoc::CoreModel::Include => method(:edge_from_include),
        Coradoc::CoreModel::Image => method(:edge_from_image),
        Coradoc::CoreModel::FootnoteElement => method(:edge_from_footnote)
      }.freeze
      private_constant :EDGE_EXTRACTORS
    end
  end
end
