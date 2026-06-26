# frozen_string_literal: true

require 'yaml'

module Coradoc
  module CoreModel
    class FrontmatterBlock
      # Single source of truth for YAML ↔ FrontmatterBlock translation.
      #
      # No other code in any gem may call YAML directly for frontmatter.
      # This isolates permitted-classes configuration and error handling
      # in one MECE location (DRY).
      #
      # Two serialization modes:
      # - +:flat+ (default) — values rendered with their natural YAML
      #   type. Matches what Jekyll, Hugo, VitePress, VuePress, 11ty and
      #   most SSGs expect: +title: Foo+ / +date: 2024-01-01+.
      # - +:typed+ — values rendered with a +value_type+ discriminator
      #   (string/integer/date/boolean/array/null). Matches the
      #   ProseMirror-compatible JSON shape emitted by the Mirror gem.
      #   Useful when downstream tooling needs explicit type tags to
      #   avoid ambiguity (e.g. ISO-date string vs Date object).
      #
      # The mode is a serialization concern — the FrontmatterBlock model
      # itself stays unchanged. Both modes round-trip to the same model.
      module Codec
        PERMITTED_CLASSES = [Date, Time, DateTime, Symbol].freeze

        # Native Ruby class → discriminator string. MECE — every
        # wrap_scalar branch derives from this table.
        DISCRIMINATOR_BY_CLASS = {
          String => 'string',
          Integer => 'integer',
          Float => 'number',
          Date => 'date',
          Time => 'datetime',
          DateTime => 'datetime',
          TrueClass => 'boolean',
          FalseClass => 'boolean',
          NilClass => 'null'
        }.freeze

        # Discriminator → reader that pulls the typed value out of the
        # discriminated hash. Used by extract_typed_value.
        TYPED_VALUE_READERS = {
          'string' => ->(h) { h['string_value'] },
          'integer' => ->(h) { h['integer_value'] },
          'number' => ->(h) { h['number_value'] },
          'boolean' => ->(h) { h['boolean_value'] },
          'date' => ->(h) { safe_parse_date(h['date_value']) },
          'datetime' => ->(h) { safe_parse_time(h['datetime_value']) },
          'null' => ->(_h) {}
        }.freeze

        # Discriminator → writer that builds the discriminated hash from
        # a native value. Used by wrap_scalar.
        TYPED_VALUE_WRITERS = {
          'string' => ->(v) { { 'value_type' => 'string', 'string_value' => v.to_s } },
          'integer' => ->(v) { { 'value_type' => 'integer', 'integer_value' => v } },
          'number' => ->(v) { { 'value_type' => 'number', 'number_value' => v } },
          'date' => ->(v) { { 'value_type' => 'date', 'date_value' => v.iso8601 } },
          'datetime' => ->(v) { { 'value_type' => 'datetime', 'datetime_value' => v.iso8601 } },
          'boolean' => ->(v) { { 'value_type' => 'boolean', 'boolean_value' => v } },
          'null' => ->(_) { { 'value_type' => 'null' } }
        }.freeze

        class << self
          # Parse YAML text into a FrontmatterBlock. Mode-agnostic —
          # both +:flat+ and +:typed+ YAML collapse to the same model
          # because the FrontmatterBlock stores native Ruby types.
          # Returns an empty FrontmatterBlock on malformed YAML.
          def from_yaml(yaml_text, mode: :flat)
            return FrontmatterBlock.new if yaml_text.nil? || yaml_text.strip.empty?

            build_from_loaded(load_yaml(yaml_text), mode: mode)
          rescue YAML::SyntaxError, Psych::DisallowedClass
            FrontmatterBlock.new
          end

          # Build a FrontmatterBlock from a Ruby hash. Mode-agnostic.
          def from_hash(hash, mode: :flat)
            return FrontmatterBlock.new unless hash.is_a?(Hash)

            build_from_loaded(hash, mode: mode)
          end

          # Serialize a FrontmatterBlock to canonical YAML text.
          # Does NOT include leading/trailing `---` delimiters; the caller
          # wraps the output. +:flat+ emits plain YAML; +:typed+ emits
          # the discriminator shape.
          def to_yaml(block, mode: :flat)
            return '' unless block.is_a?(FrontmatterBlock)

            payload = payload_for(block, mode: mode)
            return '' if payload.empty?

            YAML.dump(payload).delete_prefix("---\n").delete_suffix("\n...")
          end

          # Return the frontmatter as a Ruby hash. +:flat+ (default)
          # returns native-typed values (String, Integer, Date, …).
          # +:typed+ returns the discriminator shape used by the Mirror
          # JSON model.
          def to_hash(block, mode: :flat)
            return {} unless block.is_a?(FrontmatterBlock)

            payload_for(block, mode: mode)
          end

          private

          def load_yaml(yaml_text)
            YAML.safe_load(
              yaml_text,
              permitted_classes: PERMITTED_CLASSES,
              aliases: true
            )
          end

          def build_from_loaded(loaded, mode:)
            return FrontmatterBlock.new unless loaded.is_a?(Hash)

            data = mode == :typed ? typed_hash_to_flat(loaded) : loaded
            schema = data['$schema']
            FrontmatterBlock.new(schema: schema&.to_s, data: data.except('$schema'))
          end

          def payload_for(block, mode:)
            tree = flat_tree(block)
            return {} if tree.empty?

            mode == :typed ? flat_tree_to_typed(tree) : tree
          end

          def flat_tree(block)
            tree = {}
            tree['$schema'] = block.schema if block.schema
            tree.merge!(block.data || {})
            tree
          end

          # Flatten a discriminator-shaped hash into native values.
          # Inverse of +flat_tree_to_typed+.
          def typed_hash_to_flat(typed_hash)
            typed_hash.transform_values do |value|
              value.is_a?(Hash) ? extract_typed_value(value) : value
            end
          end

          def extract_typed_value(value_hash)
            reader = TYPED_VALUE_READERS[value_hash['value_type']]
            return reader.call(value_hash) if reader
            return extract_array(value_hash) if value_hash['value_type'] == 'array'

            value_hash['raw_value']
          end

          def extract_array(value_hash)
            Array(value_hash['items_value']).map do |item|
              item.is_a?(Hash) ? extract_typed_value(item) : item
            end
          end

          def safe_parse_date(value)
            return value if value.is_a?(Date)

            Date.iso8601(value.to_s)
          rescue Date::Error
            value
          end

          def safe_parse_time(value)
            return value if value.is_a?(Time) || value.is_a?(DateTime)

            Time.iso8601(value.to_s)
          rescue ArgumentError
            value
          end

          # Wrap each native value in a discriminator-shaped hash.
          def flat_tree_to_typed(flat)
            flat.to_h do |key, value|
              [key, key == '$schema' ? wrap_schema(value) : wrap_typed(value)]
            end
          end

          def wrap_schema(value)
            { 'value_type' => 'string', 'string_value' => value.to_s }
          end

          def wrap_typed(value)
            case value
            when Hash  then wrap_hash(value)
            when Array then wrap_array(value)
            else wrap_scalar(value)
            end
          end

          def wrap_hash(value)
            typed = { 'value_type' => 'map' }
            value.each { |k, v| typed[k.to_s] = wrap_typed(v) }
            typed
          end

          def wrap_array(value)
            {
              'value_type' => 'array',
              'items_value' => value.map { |v| wrap_typed(v) }
            }
          end

          def wrap_scalar(value)
            discriminator = DISCRIMINATOR_BY_CLASS[value.class] || 'string'
            writer = TYPED_VALUE_WRITERS[discriminator]
            writer&.call(value) || wrap_schema(value)
          end
        end
      end
    end
  end
end
