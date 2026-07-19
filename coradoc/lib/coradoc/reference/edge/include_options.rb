# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for include edges: embeds the canonical
      # CoreModel::IncludeOptions — the include directive's typed
      # selectors (tags/wildcards, lines, typed leveloffset, indent,
      # encoding). One typed form, never a re-flattened mirror.
      class IncludeOptions < Edge::Options
        attribute :include_options, Coradoc::CoreModel::IncludeOptions
      end
    end
  end
end
