# frozen_string_literal: true

module Coradoc
  # Digital twin of a corpus of source files (#137).
  #
  # A graph of FileNodes mirroring files on disk. Each node materializes
  # lazily in levels — stat (Level 0), digest (Level 1), parsed format
  # tree (Level 2) — and demotes automatically when a lower level goes
  # stale. Staleness is two-part: a node is fresh only if BOTH its
  # content digest AND its include-graph digest (the shape of the files
  # it pulls in) are unchanged. A changed file invalidates its own
  # parsed level and propagates up the include edges to every includer,
  # cycle-safe.
  #
  # The files always win: the twin is read-only derived state, and
  # consumers can never pin a stale level.
  #
  #   graph = Coradoc::SourceGraph.build("doc.adoc")
  #   node = graph.node("doc.adoc")
  #   node.parsed            # => format tree (parsed on first call)
  #   node.core              # => CoreModel (cached)
  #   graph.stale_nodes      # => nodes whose disk state drifted
  #   graph.persist          # => sidecar for O(changed) warm rebuilds
  module SourceGraph
    autoload :FileNode, "#{__dir__}/source_graph/file_node"
    autoload :Graph, "#{__dir__}/source_graph/graph"
    autoload :Sidecar, "#{__dir__}/source_graph/sidecar"
    autoload :IncludeEdges, "#{__dir__}/source_graph/include_edges"

    class << self
      def build(paths, sidecar: Sidecar.default)
        Graph.build(paths, sidecar: sidecar)
      end
    end
  end
end
