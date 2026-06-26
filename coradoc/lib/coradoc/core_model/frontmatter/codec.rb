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
      # For the typed-tree representation used by the coradoc-mirror JSON
      # pipeline, see +Coradoc::Mirror::Node::FrontmatterValue+ and
      # +Coradoc::Mirror::Handlers::Frontmatter+. The typed-tree concern
      # lives in the mirror gem; this Codec stays focused on YAML.
      module Codec
        PERMITTED_CLASSES = [Date, Time, DateTime, Symbol].freeze

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

          # Serialize a FrontmatterBlock to canonical YAML text.
          # Does NOT include leading/trailing +---+ delimiters; the
          # caller wraps the output. Returns +''+ for empty blocks.
          def to_yaml(block)
            return '' unless block.is_a?(FrontmatterBlock)

            payload = flat_tree(block)
            return '' if payload.empty?

            YAML.dump(payload).delete_prefix("---\n").delete_suffix("\n...")
          end

          # Return the frontmatter as a native-typed Ruby hash.
          # +$schema+ is included when present.
          def to_hash(block)
            return {} unless block.is_a?(FrontmatterBlock)

            flat_tree(block)
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

            schema = loaded['$schema']
            FrontmatterBlock.new(
              schema: schema&.to_s,
              data: loaded.except('$schema')
            )
          end

          def flat_tree(block)
            tree = {}
            tree['$schema'] = block.schema if block.schema
            tree.merge!(block.data || {})
            tree
          end
        end
      end
    end
  end
end
