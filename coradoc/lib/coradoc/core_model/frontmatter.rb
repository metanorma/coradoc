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
    # Entries are stored as a typed tree (FrontmatterEntry /
    # FrontmatterValue) covering every YAML.safe_load shape — scalars
    # (string, integer, float, boolean, date, datetime, symbol, nil) and
    # containers (array, map). Native-hash (de)serialization is
    # exclusively Codec's job (DRY/MECE); nothing else may build or
    # read a frontmatter hash. Order is preserved for round-trip
    # fidelity.
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

      # Typed entry tree autoloads — declared before the attribute so
      # the constant resolves; Entry and Value reference each other and
      # the lazy load breaks the cycle.
      autoload :FrontmatterValue, "#{__dir__}/frontmatter/frontmatter_value"
      autoload :FrontmatterEntry, "#{__dir__}/frontmatter/frontmatter_entry"

      # Parsed YAML frontmatter (minus `$schema`) as a typed entry
      # tree. Build via Codec.from_yaml / Codec.from_hash.
      attribute :entries, FrontmatterEntry, collection: true, default: []

      # Convenience accessor — native Ruby value for a single key.
      def entry(key)
        found = entries&.find { |e| e.key == key.to_s }
        found&.value&.to_native
      end

      def has_entry?(key)
        !entries.nil? && entries.any? { |e| e.key == key.to_s }
      end

      def empty?
        schema.nil? && (entries.nil? || entries.empty?)
      end

      def body_content?
        false
      end

      # Sub-namespaces (Codec, SchemaResolver, FieldTransform,
      # TextSplitter) live under FrontmatterBlock and autoload lazily.
      autoload :Codec, "#{__dir__}/frontmatter/codec"
      autoload :SchemaResolver, "#{__dir__}/frontmatter/schema_resolver"
      autoload :FieldTransform, "#{__dir__}/frontmatter/field_transform"
      autoload :TextSplitter, "#{__dir__}/frontmatter/text_splitter"
    end
  end
end
