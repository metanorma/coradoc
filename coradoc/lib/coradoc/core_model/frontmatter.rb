# frozen_string_literal: true

module Coradoc
  module CoreModel
    # First-class block representing YAML frontmatter attached to a
    # document.
    #
    # Frontmatter is modeled as a Block (not a side-attribute on
    # DocumentElement) so it flows through the standard block pipeline:
    # parsers produce it, transformers dispatch on its class, serializers
    # emit it. No special-casing anywhere.
    #
    # The +data+ hash stores the entire parsed YAML frontmatter (minus
    # +$schema+, which is promoted to the +schema+ attribute). Using a
    # hash — rather than a typed value tree — lets coradoc accept any
    # frontmatter shape without code changes. Type handling is delegated
    # to Ruby's native YAML/JSON, which already preserve Date, Integer,
    # Float, Boolean, nil, Array, and Hash correctly for YAML round-trips.
    #
    # The +$schema+ key, if present in source YAML, is promoted to the
    # +schema+ attribute (single source of truth — DRY); SchemaResolver
    # reads it to find validators.
    class FrontmatterBlock < Block
      def self.semantic_type
        :frontmatter
      end

      def self.element_type_name
        'frontmatter'
      end

      # `$schema` URL, nil-safe. Consumed by SchemaResolver registry.
      attribute :schema, :string

      # Entire parsed YAML frontmatter (minus `$schema`). Values are
      # native Ruby types from YAML.safe_load (String, Integer, Date,
      # Array, Hash, etc.). Order is preserved for round-trip fidelity.
      attribute :data, :hash, default: {}

      # Convenience accessor — read a single entry by key.
      def entry(key)
        data[key.to_s]
      end

      def has_entry?(key)
        data.key?(key.to_s)
      end

      def empty?
        schema.nil? && (data.nil? || data.empty?)
      end

      # Sub-namespaces (Codec, SchemaResolver, FieldTransform, TextSplitter)
      # live under FrontmatterBlock and autoload lazily.
      autoload :Codec, "#{__dir__}/frontmatter/codec"
      autoload :SchemaResolver, "#{__dir__}/frontmatter/schema_resolver"
      autoload :FieldTransform, "#{__dir__}/frontmatter/field_transform"
      autoload :TextSplitter, "#{__dir__}/frontmatter/text_splitter"
    end
  end
end
