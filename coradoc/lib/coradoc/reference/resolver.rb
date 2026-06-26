# frozen_string_literal: true

module Coradoc
  module Reference
    # Kind-agnostic resolver: given an Edge, ask the catalog, return a
    # Result. Never materializes, never slices, never orders.
    #
    #   resolver = Resolver::Catalog.new(catalog: catalog, ambiguous: :first, missing: :warn)
    #   case resolver.resolve(edge)
    #   in Result::Resolved => r ; use_target(r.target)
    #   in Result::Missing   ; warn("could not resolve #{edge.address}")
    #   end
    module Resolver
      autoload :Base, "#{__dir__}/resolver/base"
      autoload :Catalog, "#{__dir__}/resolver/catalog"
      autoload :Chain, "#{__dir__}/resolver/chain"
      autoload :Caching, "#{__dir__}/resolver/caching"
    end
  end
end
