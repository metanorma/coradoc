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
      module Codec
        PERMITTED_CLASSES = [Date, Time, DateTime, Symbol].freeze

        class << self
          # Parse a YAML string into a FrontmatterBlock.
          # Returns an empty FrontmatterBlock on malformed YAML (graceful
          # degradation — body parsing continues).
          def from_yaml(yaml_text)
            return FrontmatterBlock.new if yaml_text.nil? || yaml_text.strip.empty?

            parsed = YAML.safe_load(
              yaml_text,
              permitted_classes: PERMITTED_CLASSES,
              aliases: true
            )
            return FrontmatterBlock.new unless parsed.is_a?(Hash)

            schema = parsed['$schema']
            data = parsed.except('$schema')
            FrontmatterBlock.new(schema: schema&.to_s, data: data)
          rescue YAML::SyntaxError, Psych::DisallowedClass
            FrontmatterBlock.new
          end

          # Serialize a FrontmatterBlock to canonical YAML text.
          # Does NOT include leading/trailing `---` delimiters; the caller
          # wraps the output.
          def to_yaml(block)
            return '' unless block.is_a?(FrontmatterBlock)

            tree = {}
            tree['$schema'] = block.schema if block.schema
            tree.merge!(block.data || {})
            return '' if tree.empty?

            YAML.dump(tree).delete_prefix("---\n").delete_suffix("\n...")
          end
        end
      end
    end
  end
end
