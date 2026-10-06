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
      # The Codec emits flat YAML — values rendered with their natural
      # YAML type. This is what Jekyll, Hugo, VitePress, VuePress, 11ty
      # and every SSG expects: +title: Foo+ / +date: 2024-01-01+.
      # Round-trip fidelity for typed values (Date, Time, Symbol) is
      # preserved by Psych's permitted-classes mechanism, not by a
      # custom discriminator scheme.
      #
      # Values inside the block are stored as the typed
      # FrontmatterEntry / FrontmatterValue tree; ValueBridge below is
      # the only native ↔ typed translator. For the typed-tree
      # representation used by the coradoc-mirror JSON pipeline, see
      # +Coradoc::Mirror::Node::FrontmatterValue+ and
      # +Coradoc::Mirror::Handlers::Frontmatter+.
      module Codec
        PERMITTED_CLASSES = [Date, Time, DateTime, Symbol].freeze

        # Native Ruby values (what YAML.safe_load returns) ↔ the typed
        # FrontmatterValue tree. Adding a new scalar type is purely
        # additive: declare a typed slot on FrontmatterValue and extend
        # the case below (OCP).
        module ValueBridge
          module_function

          def native_to_value(native)
            attrs =
              case native
              when nil            then { value_type: 'nil' }
              when String         then { value_type: 'string', string_value: native }
              when Integer        then { value_type: 'integer', integer_value: native }
              when Float          then { value_type: 'float', float_value: native }
              when TrueClass, FalseClass
                { value_type: 'boolean', boolean_value: native }
              when DateTime       then { value_type: 'datetime', datetime_value: native }
              when Time           then { value_type: 'time', time_value: native }
              when Date           then { value_type: 'date', date_value: native }
              when Symbol         then { value_type: 'symbol', symbol_value: native }
              when Array
                { value_type: 'array', items: native.map { |v| native_to_value(v) } }
              when Hash
                {
                  value_type: 'map',
                  entries: native.map do |k, v|
                    FrontmatterEntry.new(key: k.to_s, value: native_to_value(v))
                  end
                }
              else
                { value_type: 'string', string_value: native.to_s }
              end
            FrontmatterValue.new(attrs)
          end
        end
        private_constant :ValueBridge

        class << self
          # Parse YAML text into a FrontmatterBlock. Returns an empty
          # FrontmatterBlock on malformed YAML or non-Hash payload.
          # Logs a warning so the conversion pipeline can surface the
          # skip rather than silently dropping user-authored content.
          def from_yaml(yaml_text)
            return FrontmatterBlock.new if yaml_text.nil? || yaml_text.strip.empty?

            build_from_loaded(load_yaml(yaml_text))
          rescue YAML::SyntaxError, Psych::DisallowedClass => e
            Coradoc::Logger.warn("frontmatter parse failed: #{e.message}")
            FrontmatterBlock.new
          end

          # Build a FrontmatterBlock from a Ruby hash with native-typed
          # values (String, Integer, Date, …). Returns an empty block
          # for non-Hash input.
          def from_hash(hash)
            return FrontmatterBlock.new unless hash.is_a?(Hash)

            build_from_loaded(hash)
          end

          # Typed entries for a native hash — the bridge used by
          # from_hash/from_yaml and by callers constructing blocks
          # entry-by-entry (e.g., the mirror reverse builder).
          def entries_from_hash(hash)
            return [] unless hash.is_a?(Hash)

            hash.map do |key, value|
              FrontmatterEntry.new(key: key.to_s, value: ValueBridge.native_to_value(value))
            end
          end

          # Serialize a FrontmatterBlock to canonical YAML text.
          # Does NOT include leading/trailing +---+ delimiters; the
          # caller wraps the output. Returns +''+ for empty blocks.
          def to_yaml(block)
            return '' unless block.is_a?(FrontmatterBlock)

            payload = flat_tree(block)
            return '' if payload.empty?

            YAML.dump(payload).delete_prefix("---\n").delete_suffix("\n...")
          end

          # Return the frontmatter entries as a native-typed Ruby hash
          # (the block's data, WITHOUT +$schema+ — the schema attribute
          # is read separately).
          def to_hash(block)
            return {} unless block.is_a?(FrontmatterBlock)

            block.entries.to_a.each_with_object({}) { |e, h| h[e.key] = e.to_native }
          end

          private

          def load_yaml(yaml_text)
            YAML.safe_load(
              yaml_text,
              permitted_classes: PERMITTED_CLASSES,
              aliases: true
            )
          end

          def build_from_loaded(loaded)
            return FrontmatterBlock.new unless loaded.is_a?(Hash)

            FrontmatterBlock.new(
              schema: loaded['$schema']&.to_s,
              entries: entries_from_hash(loaded.except('$schema'))
            )
          end

          def flat_tree(block)
            tree = {}
            tree['$schema'] = block.schema if block.schema
            block.entries.to_a.each { |e| tree[e.key] = e.to_native }
            tree
          end
        end
      end
    end
  end
end
