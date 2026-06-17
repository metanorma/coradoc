# frozen_string_literal: true

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # OCP registry mapping `$schema` URLs to validator classes.
      #
      # Core ships with NO built-in validators. Downstream gems (e.g.,
      # a future `coradoc-jsonschema`) register resolvers without
      # modifying core code.
      module SchemaResolver
        # Structured validation error. Typed — never a hash bag.
        ValidationError = Struct.new(:field, :message, keyword_init: true)

        # Base class for schema resolvers. Override #validate in subclasses.
        class Base
          def validate(_block)
            []
          end
        end

        # Registry of URL → resolver class.
        class Registry
          DEFAULT = new

          def initialize
            @resolvers = {}
          end

          def register(schema_url, resolver_class)
            @resolvers[schema_url.to_s] = resolver_class
          end

          def lookup(schema_url)
            @resolvers[schema_url.to_s]
          end

          def registered?(schema_url)
            @resolvers.key?(schema_url.to_s)
          end

          # Returns array of ValidationError structs. Empty if no schema,
          # no resolver, or validation passes.
          def validate(block)
            return [] unless block.is_a?(FrontmatterBlock)
            return [] if block.schema.nil?

            resolver_class = lookup(block.schema)
            return [] unless resolver_class

            resolver_class.new.validate(block)
          end
        end
      end
    end
  end
end
