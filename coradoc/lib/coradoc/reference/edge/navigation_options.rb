# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options specific to navigation edges (xref, anchor).
      class NavigationOptions < Edge::Options
        attribute :link_text, :string
        attribute :tooltip, :string
      end
    end
  end
end
