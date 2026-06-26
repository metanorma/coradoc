# frozen_string_literal: true

module Coradoc
  module Reference
    # Externally-built index from Address → Content. coradoc queries
    # catalogs; it never owns the collection truth.
    #
    # A Catalog is any object responding to +lookup+, +each_pair+, and
    # +recognizes_scheme?+. Built-in catalogs share an in-memory index
    # (MemoryIndex) for implementation. Catalogs compose via CompositeCatalog.
    module Catalog
      autoload :MemoryIndex, "#{__dir__}/catalog/memory_index"
      autoload :Local, "#{__dir__}/catalog/local"
      autoload :Composite, "#{__dir__}/catalog/composite"

      # Protocol methods every Catalog must answer. Implementations may
      # include this module for documentation only; the protocol is
      # duck-typed but explicit at the type-check sites via these method
      # names.
      module Protocol
        # Resolve +address+ to a Content node (CoreModel::Base) or nil.
        def lookup(address) = raise(NotImplementedError)

        # Enumerate every (Address, Content) pair this catalog knows.
        def each_pair(&) = raise(NotImplementedError)

        # Does this catalog index addresses of the given scheme? Used by
        # composite catalogs to skip irrelevant children.
        def recognizes_scheme?(scheme) = raise(NotImplementedError)
      end
    end
  end
end
