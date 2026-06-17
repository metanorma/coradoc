# 02 — CoreModel FrontmatterBlock

## Goal

Make YAML frontmatter a first-class Block in CoreModel so it flows through
the existing block pipeline (children array, transform dispatch, serializer
dispatch) with zero special-casing.

## Why

- Treating frontmatter as a Block is OCP-clean: serializers and
  transformers already dispatch on class. A new `FrontmatterBlock` subclass
  just plugs in.
- MECE: document-level metadata lives in `children[0]` as a typed block,
  not as a side-attribute on `DocumentElement`.
- Schema-awareness: `$schema` is promoted to a first-class `schema`
  attribute so resolvers can find it without scanning entries.

## Files

- `coradoc/lib/coradoc/core_model/frontmatter.rb`
  - `FrontmatterBlock < Block`
    - `attribute :schema, :string` — `$schema` URL, nil-safe
    - `attribute :entries, FrontmatterEntry, collection: true`
    - `semantic_type :frontmatter`
    - `element_type_name 'frontmatter'`
    - `entry(key)` / `has_entry?(key)` lookups
  - `FrontmatterEntry < Base`
    - `attribute :key, :string`
    - `attribute :value, MetadataValue` (polymorphic over the tree from TODO 01)
- `coradoc/lib/coradoc/core_model.rb` — autoload entries
- `coradoc/spec/core_model/frontmatter_spec.rb`

## Semantics

- `$schema` is consumed by the codec (TODO 03) and stored on
  `FrontmatterBlock#schema`; it is NOT re-inserted into `entries` to avoid
  duplication (DRY).
- `FrontmatterBlock` participates in `DocumentElement#children` like any
  other Block; format serializers decide placement.
- Schema resolvers (TODO 04) read `block.schema` to find validators.

## Out of scope

- YAML codec (TODO 03)
- Schema resolution (TODO 04)
- Field transforms (TODO 05)

## Status

Implemented.
