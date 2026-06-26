# frozen_string_literal: true

module Coradoc
  module Reference
    module Catalog
      # Shared in-memory index. Built-in catalogs compose this rather
      # than reimplementing the storage layer (DRY). The index is
      # immutable from the outside — entries are added by the catalog
      # during construction, then read-only.
      class MemoryIndex
        include Enumerable

        def initialize
          @by_address = {}
          @schemes = Set.new
        end

        def add(address, content)
          raise ArgumentError, 'address required' unless address.is_a?(Coradoc::Reference::Address)
          raise ArgumentError, 'content required' unless content

          @by_address[address] = Array(@by_address[address]) << content
          @schemes << address.scheme.to_sym
          self
        end

        def lookup(address)
          entries = @by_address[address]
          return nil unless entries
          return entries.first if entries.size == 1

          entries
        end

        def ambiguous?(address)
          entries = @by_address[address]
          entries && entries.size > 1
        end

        def each_pair
          return to_enum(:each_pair) unless block_given?

          @by_address.each do |address, contents|
            contents.each { |c| yield address, c }
          end
        end

        def recognizes_scheme?(scheme)
          @schemes.include?(scheme.to_sym)
        end

        def size
          @by_address.size
        end
      end
    end
  end
end
