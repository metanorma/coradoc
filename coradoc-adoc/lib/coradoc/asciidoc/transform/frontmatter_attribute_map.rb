# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # OCP opt-in bridge mapping AsciiDoc document attributes
      # (`:author:`, `:revdate:`, etc.) to/from FrontmatterBlock data.
      #
      # NOT auto-registered. Users opt in by invoking the bridge methods
      # from their pipeline (e.g., from a custom transformer extension
      # or rake task). This honors OCP: core conversion never silently
      # rewrites data; opt-in extensions add behavior explicitly.
      #
      # MECE: lives in its own file, dispatches on `attribute_name` /
      # `frontmatter_key` pairs. Does not touch FrontmatterBlock::Codec
      # (YAML I/O) or SchemaResolver (validation).
      #
      # Mappings (bidirectional):
      #
      #   | Frontmatter key | AsciiDoc attribute | Notes              |
      #   |-----------------|--------------------|--------------------|
      #   | author          | author             |                    |
      #   | date            | revdate            |                    |
      #   | tags            | tags               | Array <-> space str|
      #   | categories      | categories         | Array <-> space str|
      module FrontmatterAttributeMap
        # Single source of truth for the attribute <-> frontmatter
        # mapping. Each tuple: [attribute_name(String), front_key(String),
        # kind(:scalar | :array)]
        MAPPINGS = [
          ['author', 'author', :scalar],
          ['revdate', 'date', :scalar],
          ['tags', 'tags', :array],
          ['categories', 'categories', :array]
        ].freeze

        class << self
          # Build a frontmatter data hash from an AsciiDoc document
          # attributes Hash. Skips unknown keys and empty values.
          #
          # @param attributes [Hash{String=>Object}] AsciiDoc document
          #   attributes (e.g., from DocumentAttributes#to_hash)
          # @return [Hash{String=>Object}] frontmatter data hash
          def entries_from_attributes(attributes)
            attributes = normalize_hash(attributes)
            MAPPINGS.each_with_object({}) do |(attr_name, front_key, kind), h|
              raw = attributes[attr_name]
              next if raw.nil? || raw.to_s.strip.empty?

              h[front_key] = build_value(raw, kind)
            end
          end

          # Reverse: walk a FrontmatterBlock's data and produce a Hash
          # of AsciiDoc document attributes. Unknown entry keys are
          # dropped (only mapped keys are translated).
          #
          # @param block [Coradoc::CoreModel::FrontmatterBlock]
          # @return [Hash{String=>String}]
          def attributes_from_block(block)
            result = {}
            return result unless block&.data

            MAPPINGS.each do |(_, front_key, _)|
              value = block.data[front_key]
              next if value.nil?

              attr_name = front_key_to_attribute(front_key)
              next unless attr_name

              result[attr_name] = serialize_value(value)
            end
            result
          end

          private

          def normalize_hash(attributes)
            return {} unless attributes.is_a?(Hash)

            attributes.each_with_object({}) do |(k, v), h|
              h[k.to_s] = v
            end
          end

          def build_value(raw, kind)
            case kind
            when :array
              raw.to_s.split(/\s+/).reject(&:empty?)
            else
              raw.to_s
            end
          end

          def serialize_value(value)
            case value
            when Array
              value.map(&:to_s).join(' ')
            else
              value.to_s
            end
          end

          def front_key_to_attribute(front_key)
            mapping = MAPPINGS.find { |_, fk, _| fk == front_key.to_s }
            mapping&.first
          end
        end
      end
    end
  end
end
