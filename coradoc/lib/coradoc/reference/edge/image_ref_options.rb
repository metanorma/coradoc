# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options for image references.
      class ImageRefOptions < Edge::Options
        attribute :alt_text, :string
        attribute :width, :string
        attribute :height, :string
        attribute :role, :string
      end
    end
  end
end
