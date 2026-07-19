# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options base class. Subclasses are typed value objects per kind —
      # never +:hash+. Value equality (==/eql?/hash) comes from
      # Lutaml::Model: class-aware, all attributes compared.
      class Options < Lutaml::Model::Serializable
      end
    end
  end
end
