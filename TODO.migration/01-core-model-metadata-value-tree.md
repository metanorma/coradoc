# 01 — CoreModel MetadataValue Tree

## Goal

Provide a fully typed, hash-free algebra for representing arbitrary YAML
scalar/array/map structures inside CoreModel. This is the foundation that
lets frontmatter round-trip without ever using a Ruby `Hash` inside a model.

## Why

- Project rule: **NO HASHES IN MODELS**. Existing `CoreModel::MetadataEntry`
  has `value, :string`, which cannot represent `authors: [...]` or nested
  maps. We need a typed value tree.
- MECE: one place owns "how to represent a YAML value", everyone else uses
  it.
- OCP: new value types are added by subclassing, not editing dispatch.

## Files

- `coradoc/lib/coradoc/core_model/metadata_value.rb`
  - `MetadataValue` (abstract base; `kind` symbolic; `to_ruby` / `to_yaml_node`)
  - `ScalarMetadataValue` — `raw: String`, `scalar_type: String` (one of
    `string|integer|float|boolean|date|datetime|null|symbol`)
  - `ArrayMetadataValue` — `items: MetadataValue[]` (polymorphic)
  - `MapMetadataValue` — `entries: MapMetadataEntry[]`
  - `MapMetadataEntry` — `key: String`, `value: MetadataValue` (polymorphic)
- `coradoc/lib/coradoc/core_model.rb` — autoload `MetadataValue`, all
  subclasses, and `MapMetadataEntry`
- `coradoc/spec/core_model/metadata_value_spec.rb`

## Behavior

- Each scalar type round-trips through `to_ruby` / `from_ruby` correctly.
- `ArrayMetadataValue#items` preserves element order and types.
- `MapMetadataValue#entries` preserves insertion order, allows duplicate
  keys (YAML allows duplicates; we preserve and emit in order).
- Equality is structural.

## Out of scope

- Schema validation (TODO 06)
- Codec (TODO 03)
- Format integration (TODO 02, 04, 05)

## Status

Implemented.
