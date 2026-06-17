# 03 — Frontmatter YAML Codec

## Goal

Single source of truth for translating between YAML text and the typed
`FrontmatterBlock`. No other code in any gem may call `YAML` directly for
frontmatter.

## Why

- DRY: one codec, one set of type-detection rules, one set of permitted
  classes.
- MECE: parsing concerns live here, not in format parsers.
- Testable in isolation from any format.

## Files

- `coradoc/lib/coradoc/core_model/frontmatter/codec.rb`
  - `Frontmatter::Codec.from_yaml(yaml_string) → FrontmatterBlock`
  - `Frontmatter::Codec.to_yaml(frontmatter_block) → String`
  - Permitted classes: `[Date, Time, DateTime, Symbol]`
  - On parse error: return empty `FrontmatterBlock` (graceful)
- `coradoc/spec/core_model/frontmatter/codec_spec.rb`

## Behavior

### from_yaml

- Empty / malformed YAML → empty `FrontmatterBlock`
- `$schema` key extracted to `block.schema`; remaining keys become entries
  in declaration order
- Type mapping:
  - `String` → `ScalarMetadataValue(raw, "string")`
  - `Integer` → `ScalarMetadataValue(raw, "integer")`
  - `Float` → `ScalarMetadataValue(raw, "float")`
  - `true`/`false` → `ScalarMetadataValue(raw, "boolean")`
  - `nil` → `ScalarMetadataValue("", "null")`
  - `Date` → `ScalarMetadataValue(iso8601, "date")`
  - `DateTime`/`Time` → `ScalarMetadataValue(iso8601, "datetime")`
  - `Symbol` → `ScalarMetadataValue(raw, "symbol")`
  - `Array` → `ArrayMetadataValue(items: [...])`
  - `Hash` → `MapMetadataValue(entries: [...])`

### to_yaml

- Inverse of above
- Emits `$schema` first if `block.schema` is set
- Emits entries in declaration order
- Returns canonical YAML text (no leading `---\n` — the caller adds
  delimiters)

## Out of scope

- Delimiter handling (`---` wrapping) — caller's responsibility
- Schema validation (TODO 04)

## Status

Implemented.
