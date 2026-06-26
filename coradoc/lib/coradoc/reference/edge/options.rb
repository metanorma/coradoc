# frozen_string_literal: true

module Coradoc
  module Reference
    class Edge < Lutaml::Model::Serializable
      # Options base class. Subclasses are typed value objects per kind —
      # never +:hash+. Subclass per kind carries kind-specific hints.
      class Options < Lutaml::Model::Serializable
        attribute :format, :string

        def ==(other)
          return false unless other.is_a?(self.class)

          self.class.attributes.keys.all? do |attr|
            public_send(attr) == other.public_send(attr)
          end
        end
        alias eql? ==

        def hash
          self.class.attributes.keys.map { |a| public_send(a) }.hash
        end
      end
    end
  end
end
