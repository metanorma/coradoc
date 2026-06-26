# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for hyperlink edges.
      class LinkOptions < Edge::Options
        attribute :link_text, :string
        attribute :role, :string
      end
    end
  end
end
