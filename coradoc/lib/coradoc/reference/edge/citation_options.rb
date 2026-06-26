# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for citation edges (bib references). Style is the
      # citation style name (e.g. "ieee", "apa", "chicago"); locality
      # is the optional page/section reference carried separately on
      # Address.fragment, not here.
      class CitationOptions < Edge::Options
        attribute :style, :string
        attribute :suppress_author, :boolean, default: -> { false }
      end
    end
  end
end
