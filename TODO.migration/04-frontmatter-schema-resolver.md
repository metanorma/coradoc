# 04 — Frontmatter SchemaResolver Registry

## Goal

OCP registry that maps `$schema` URLs to validator classes, so third-party
gems can register schema validators (JSON Schema, custom DSLs, etc.)
without modifying core.

## Why

- OCP: adding a schema validator = register, not edit.
- MECE: validation logic lives in resolvers, not in the codec or block.
- Decoupling: core knows nothing about JSON Schema; resolvers are pluggable.

## Files

- `coradoc/lib/coradoc/core_model/frontmatter/schema_resolver.rb`
  - `Frontmatter::SchemaResolver::Base`
    - `validate(block) → Array<ValidationError>` (abstract; override)
  - `Frontmatter::SchemaResolver::Registry`
    - `register(schema_url, resolver_class)`
    - `lookup(schema_url) → resolver_class or nil`
    - `validate(block) → Array<ValidationError>` (no-op when no resolver)
- `coradoc/lib/coradoc/core_model.rb` — autoload
- `coradoc/spec/core_model/frontmatter/schema_resolver_spec.rb`

## Behavior

- Default registry is empty. No built-in schema validators.
- `Registry.validate(block)`:
  - Returns `[]` if `block.schema.nil?`
  - Returns `[]` if no resolver registered for the schema URL
  - Returns resolver's validation errors otherwise
- `ValidationError` is a typed Struct (field, message) — not a hash.

## Future resolvers (separate gems, not in scope)

- `coradoc-jsonschema` — registers JSON Schema validator
- `coradoc-frontmatter-schemas` — common blog/CMS schemas
- Custom internal schemas

## Status

Implemented (registry only; concrete resolvers are TODO for downstream
gems).
