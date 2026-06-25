# frozen_string_literal: true

module Coradoc
  module Mirror
    # Walks a typed FrontmatterEntry / FrontmatterValue tree (the Mirror
    # representation of CoreModel::FrontmatterBlock#data) and rebuilds the
    # flat Ruby Hash. Inverse of Handlers::Frontmatter.build_value.
    #
    # Single source of truth for tree → Hash translation. Consumed by:
    #   - ReverseBuilder::Frontmatter (mirror → CoreModel round-trip)
    #   - FrontmatterQuery (mirror doc → flat Hash for downstream readers)
    #
    # Extracted from ReverseBuilder so the read-path is shared (DRY/MECE)
    # and FrontmatterQuery does not depend on the reverse-builder constant.
    module FrontmatterTreeToHash
      module_function

      def to_hash(entries)
        entries.each_with_object({}) do |entry, result|
          result[entry.key] = unwrap_value(entry.value)
        end
      end

      def unwrap_value(value)
        case value.value_type
        when 'map'     then to_hash(value.entries || [])
        when 'array'   then (value.items || []).map { |v| unwrap_value(v) }
        when 'integer'   then value.integer_value
        when 'float'     then value.float_value
        when 'boolean'   then value.boolean_value
        when 'date'      then value.date_value
        when 'datetime'  then value.datetime_value
        when 'symbol'    then value.symbol_value&.to_sym
        when 'nil'       then nil
        else value.string_value
        end
      end
    end
  end
end
