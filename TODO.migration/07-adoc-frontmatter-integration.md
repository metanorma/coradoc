# 07 — AsciiDoc Frontmatter Integration

## Goal

AsciiDoc does not have native YAML frontmatter, but its document
attributes (`:author:`, `:revdate:`, `:title:`) carry the same semantic
information. Map them bidirectionally to `FrontmatterBlock`.

## Why

- Enables `.adoc` → CoreModel → `.md` frontmatter round-trip via known
  attribute keys.
- Keeps AsciiDoc's native model untouched; mapping happens at transform
  boundaries only.

## Files

- `coradoc-adoc/lib/coradoc/asciidoc/transform/element_transformers/document_transformer.rb`
  - When building `CoreModel::DocumentElement`, if known document
    attributes are present (author, revdate, title, tags, categories),
    build a `FrontmatterBlock` and prepend to children
- `coradoc-adoc/lib/coradoc/asciidoc/transform/from_core_model.rb`
  - When serializing CoreModel → AsciiDoc, if
    `core_doc.children.first` is a `FrontmatterBlock`, map known entries
    back to AsciiDoc document attributes
- `coradoc-adoc/lib/coradoc/asciidoc/transform/frontmatter_attribute_map.rb`
  - Bidirectional key map: `author ↔ author`, `date ↔ revdate`,
    `title ↔ title`, etc.
- Specs:
  - `coradoc-adoc/spec/transform/frontmatter_from_document_attributes_spec.rb`
  - `coradoc-adoc/spec/transform/frontmatter_to_document_attributes_spec.rb`

## Attribute mapping

| Frontmatter key | AsciiDoc attribute | Notes |
|---|---|---|
| `title` | `title` (header) | Already mapped via header.title |
| `author` | `author` | |
| `date` | `revdate` | |
| `tags` | `tags` (space-separated) | Array → string |
| `categories` | `categories` (space-separated) | Array → string |
| Other | dropped | Unknown keys not representable in adoc attrs |

## Behavior

- Round-trip `.adoc` with author/date → CoreModel FrontmatterBlock →
  Markdown emits them as YAML frontmatter.
- `.md` with frontmatter → CoreModel → `.adoc` emits `:author:` etc.

## Out of scope

- HTML meta tag mapping (TODO 08)
- DOCX core properties mapping (TODO 09)

## Status

TODO — defer to follow-up PR. Architecture in place; only the mapping
file and the two transformer hooks need wiring.
