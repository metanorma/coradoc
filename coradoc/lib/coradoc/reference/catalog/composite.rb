# frozen_string_literal: true

module Coradoc
  module Reference
    module Catalog
      # Composes multiple catalogs. Lookup tries each child in order;
      # the first non-nil result wins. This is the catalog callers reach
      # for in production:
      #
      #   Composite.new(
      #     Local.from_doc(doc),
      #     Collection.from_manifest(...),
      #     Remote.new(client: http_client)
      #   )
      class Composite
        include Catalog::Protocol

        attr_reader :children

        def initialize(*children)
          @children = children.flatten
        end

        def lookup(address)
          results = []
          children.each do |catalog|
            result = catalog.lookup(address)
            next if result.nil?

            results.concat(Array(result))
          end
          return nil if results.empty?
          return results.first if results.size == 1

          results
        end

        def ambiguous?(address)
          lookup(address).is_a?(Array) && lookup(address).size > 1
        end

        def each_pair(&block)
          return to_enum(:each_pair) unless block_given?

          children.each do |catalog|
            catalog.each_pair(&block)
          end
        end

        def recognizes_scheme?(scheme)
          children.any? { |catalog| catalog.recognizes_scheme?(scheme) }
        end
      end
    end
  end
end
