# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Reference
    module Result
      # Base class for resolution outcomes. Subclasses are value types.
      # Every Result carries the Edge that asked — so callers can log,
      # trace, and re-route without re-resolving.
      class Base < Lutaml::Model::Serializable
        attribute :edge, Coradoc::Reference::Edge
        attribute :address, Coradoc::Reference::Address

        def resolved?
          is_a?(Result::Resolved)
        end

        def ambiguous?
          is_a?(Result::Ambiguous)
        end

        def missing?
          is_a?(Result::Missing)
        end

        def deferred?
          is_a?(Result::Deferred)
        end

        # This Result as seen by +edge+. Returns self when the edge is
        # value-equal to the one embedded; otherwise rebuilds the same
        # outcome (target/candidates preserved) for the asking edge.
        # Used by caching resolvers so two edges sharing an Address
        # never see each other's identity.
        def for_edge(edge)
          return self if self.edge == edge

          self.class.build(edge: edge, address: address, **result_data)
        end

        private

        def result_data
          {}
        end
      end
    end
  end
end
