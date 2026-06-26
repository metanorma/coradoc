# frozen_string_literal: true

module Coradoc
  module Reference
    module Resolver
      # Asks one catalog. Applies the +ambiguous:+ policy in-line.
      # Does NOT apply the +missing:+ policy — that's the caller's
      # call (Resolution orchestrator) — but it does surface the
      # Missing Result so the caller can decide.
      class Catalog < Resolver::Base
        attr_reader :catalog, :ambiguous_policy, :missing_policy

        def initialize(catalog:, ambiguous: :disambiguate, missing: :warn)
          super()
          @catalog = catalog
          @ambiguous_policy = ambiguous
          @missing_policy = missing
        end

        def resolve(edge)
          address = edge.address
          return missing_for(edge, address) unless catalog.recognizes_scheme?(address.scheme)

          result = catalog.lookup(address)
          return missing_for(edge, address) if result.nil?

          return resolved_for(edge, address, result) unless result.is_a?(Array)

          resolve_ambiguous(edge, address, result)
        end

        private

        def resolved_for(edge, address, target)
          Coradoc::Reference::Result::Resolved.build(
            edge: edge, address: address, target: target
          )
        end

        def resolve_ambiguous(edge, address, candidates)
          return ambiguous_error(address, candidates) if ambiguous_policy == :error
          return resolved_for(edge, address, candidates.first) if ambiguous_policy == :first

          Coradoc::Reference::Result::Ambiguous.build(
            edge: edge, address: address, candidates: candidates
          )
        end

        def ambiguous_error(address, candidates)
          raise Coradoc::Reference::AmbiguousReferenceError,
                "Address #{address} matched #{candidates.size} candidates"
        end

        def missing_for(edge, address)
          case missing_policy
          when :error
            raise Coradoc::Reference::MissingReferenceError,
                  "Address #{address} not found"
          else
            Coradoc::Reference::Result::Missing.build(edge: edge, address: address)
          end
        end
      end
    end
  end
end
