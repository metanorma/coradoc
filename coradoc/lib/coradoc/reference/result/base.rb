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
      end
    end
  end
end
