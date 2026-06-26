# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for include edges. Mirror the asciidoctor include
      # selectors (tags, lines, leveloffset, indent, encoding) but as
      # typed attributes — the existing CoreModel::IncludeOptions
      # remains the canonical form; this is the reference-graph mirror.
      class IncludeOptions < Edge::Options
        attribute :tags, :string, collection: true, default: -> { [] }
        attribute :lines_spec, :string
        attribute :leveloffset, :string
        attribute :indent, :integer
        attribute :file_encoding, :string
      end
    end
  end
end
