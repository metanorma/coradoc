# frozen_string_literal: true

module Coradoc
  module Reference
    module Resolver
      # Tries each child resolver in order. First non-Missing result
      # wins (Resolved, Ambiguous, or Deferred short-circuit). Use to
      # combine a local catalog with a remote one without composite
      # catalog indirection.
      class Chain < Resolver::Base
        attr_reader :resolvers

        def initialize(*resolvers)
          super()
          @resolvers = resolvers.flatten
        end

        def resolve(edge)
          last = nil
          @resolvers.each do |resolver|
            result = resolver.resolve(edge)
            return result unless result.is_a?(Coradoc::Reference::Result::Missing)

            last = result
          end
          last || Coradoc::Reference::Result::Missing.build(
            edge: edge, address: edge.address
          )
        end
      end
    end
  end
end
