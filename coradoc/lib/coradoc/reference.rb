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
    # Base class for reference-resolution errors. All subclasses inherit
    # from here so callers can rescue the family with one +rescue+ clause.
    class Error < Coradoc::Error; end

    # Raised when no catalog knew the requested Address and the
    # +missing:+ policy is :error.
    class MissingReferenceError < Error
      attr_reader :address

      def initialize(message = nil, address: nil)
        @address = address
        super(message || "Reference not found: #{address}")
      end
    end

    # Raised when multiple catalogs matched an Address and the
    # +ambiguous:+ policy is :error.
    class AmbiguousReferenceError < Error
      attr_reader :address, :candidates

      def initialize(message = nil, address: nil, candidates: nil)
        @address = address
        @candidates = candidates
        super(message || "Reference is ambiguous: #{address}")
      end
    end

    # Raised when the catalog index is malformed — a programmer
    # error, not a runtime condition. Surfaces as a clear message
    # rather than a vague NoMethodError.
    class InvalidCatalogError < Error; end

    # Raised when building an Edge whose kind was never registered.
    # External kinds register via +Edge.register_kind+ (OCP).
    class UnknownKindError < Error; end

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
