# frozen_string_literal: true

module Coradoc
  # Unified content-graph reference resolution.
  #
  # Every referenceable thing in a document is a Content node; every
  # reference is a directed Edge with a kind. The four primitives:
  #
  #   Content             — CoreModel::Base with an id (already on Base).
  #   Document            — Content that contains Content (composite).
  #   Reference::Edge     — directed {source Content, target Address, kind}.
  #   Reference::Address  — scheme-aware locator (anchor, path, url, ...).
  #
  # Same Content graph → N Presentations → M Materializers. The public
  # entry point is +Coradoc.resolve_references+.
  module Reference
    autoload :Address, "#{__dir__}/reference/address"
    autoload :Edge, "#{__dir__}/reference/edge"
    autoload :Catalog, "#{__dir__}/reference/catalog"
    autoload :Result, "#{__dir__}/reference/result"
    autoload :Resolver, "#{__dir__}/reference/resolver"
    autoload :Presentation, "#{__dir__}/reference/presentation"
    autoload :Materializer, "#{__dir__}/reference/materializer"
    autoload :EdgeSearch, "#{__dir__}/reference/edge_search"
    autoload :Resolution, "#{__dir__}/reference/resolution"
  end
end
