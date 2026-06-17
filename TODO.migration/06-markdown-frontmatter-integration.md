# 06 — Markdown Frontmatter Integration

## Goal

Full Markdown support: parse YAML frontmatter at document start, round-trip
through CoreModel, serialize back to YAML frontmatter.

## Why

- Markdown is the format that natively has frontmatter. This is the
  reference integration.
- Demonstrates the architecture end-to-end with real input.

## Files

- `coradoc-markdown/lib/coradoc/markdown/parser/frontmatter_parser.rb`
  - Standalone Parslet parser for `---\n...\n---\n` block
  - `parse(text) → { frontmatter: "...", body: "..." }` Struct
- `coradoc-markdown/lib/coradoc/markdown.rb` — entry point delegates to
  FrontmatterParser before BlockParser
- `coradoc-markdown/lib/coradoc/markdown/transform/to_core_model.rb`
  - When Markdown Document was built from frontmatter, wrap a
    `FrontmatterBlock` and prepend to `core_doc.children`
- `coradoc-markdown/lib/coradoc/markdown/transform/from_core_model.rb`
  - When `core_doc.children.first` is a `FrontmatterBlock`, extract it
    into Markdown Document's `frontmatter` slot
- `coradoc-markdown/lib/coradoc/markdown/serializer.rb`
  - Emit `---\n#{Codec.to_yaml(block)}---\n\n` before body when frontmatter
    present
- `coradoc-markdown/lib/coradoc/markdown.rb` — autoload
- Specs:
  - `coradoc-markdown/spec/parser/frontmatter_parser_spec.rb`
  - `coradoc-markdown/spec/transform/frontmatter_round_trip_spec.rb`
  - `coradoc-markdown/spec/serializer/frontmatter_serialization_spec.rb`

## Behavior

- Empty body with frontmatter → Document with one FrontmatterBlock child
- No frontmatter → Document unchanged
- Malformed YAML → FrontmatterBlock with zero entries, body still parsed
- End-to-end: `.md` → CoreModel → `.md` preserves frontmatter + body

## Status

Implemented.
