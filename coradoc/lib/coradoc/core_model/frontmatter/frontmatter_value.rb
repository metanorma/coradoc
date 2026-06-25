# frozen_string_literal: true

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # Single typed value node in a FrontmatterBlock entry tree.
      #
      # Replaces the previous `attribute :data, :hash` representation.
      # Each value carries a `value_type` discriminator plus one populated
      # slot matching that type. Container types (`array`, `map`) hold
      # nested FrontmatterValue / FrontmatterEntry children.
      #
      # Supported value types (mirror what YAML.safe_load returns given
      # the Codec's PERMITTED_CLASSES):
      #
      #   scalar  -> string, integer, float, boolean, date, datetime, symbol, nil
      #   container -> array, map
      #
      # Adding a new scalar type is purely additive: declare a new typed
      # slot and extend the case in Codec::ValueBridge (OCP).
      class FrontmatterValue < Base
        SCALAR_TYPES = %w[
          string integer float boolean date datetime symbol nil
        ].freeze
        CONTAINER_TYPES = %w[array map].freeze
        ALL_TYPES = (SCALAR_TYPES + CONTAINER_TYPES).freeze

        attribute :value_type, :string

        # Scalar slots — exactly one populated, selected by value_type.
        attribute :string_value, :string
        attribute :integer_value, :integer
        attribute :float_value, :float
        attribute :boolean_value, :boolean
        attribute :date_value, :date
        attribute :datetime_value, :date_time
        attribute :symbol_value, :symbol

        # Container slots — populated when value_type is array/map.
        attribute :items, FrontmatterValue, collection: true
        attribute :entries, FrontmatterEntry, collection: true

        # Convenience: return the Ruby-native scalar value for this node,
        # or nil for containers / nil-typed values. Used by callers that
        # don't care about the type discriminator.
        def ruby_value
          case value_type
          when 'string'   then string_value
          when 'integer'  then integer_value
          when 'float'    then float_value
          when 'boolean'  then boolean_value
          when 'date'     then date_value
          when 'datetime' then datetime_value
          when 'symbol'   then symbol_value
          when 'nil'      then nil
          end
        end
      end
    end
  end
end
