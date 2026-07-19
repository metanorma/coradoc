# frozen_string_literal: true

module Coradoc
  module Reference
    module Resolver
      # Wraps another resolver with an address-keyed memoization cache.
      # Addresses are value types, so cache keys are stable across calls.
      # Use to avoid re-asking the catalog for the same Edge.address.
      class Caching < Resolver::Base
        attr_reader :inner

        def initialize(inner:)
          super()
          @inner = inner
          @cache = {}
        end

        def resolve(edge)
          cached = if @cache.key?(edge.address)
                     @cache[edge.address]
                   else
                     @cache[edge.address] = @inner.resolve(edge)
                   end
          cached.for_edge(edge)
        end

        def clear!
          @cache.clear
        end

        def size
          @cache.size
        end
      end
    end
  end
end
