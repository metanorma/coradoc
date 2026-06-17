# 05 — Frontmatter FieldTransform Registry

## Goal

OCP registry for semantic field transforms applied during conversion
(e.g., `authors` array → `author` string when emitting Markdown for
Jekyll).

## Why

- These transforms are *directional* and *format-specific*, but the
  mechanism should be uniform.
- OCP: registering a new transform requires no edits to dispatch code.
- MECE: the codec handles YAML; transforms handle semantic renames.

## Files

- `coradoc/lib/coradoc/core_model/frontmatter/field_transform.rb`
  - `Frontmatter::FieldTransform::Base`
    - `applies?(direction:, format:) → Boolean` (override)
    - `apply(entry) → Entry | Array<Entry> | nil` (override; nil = drop)
  - `Frontmatter::FieldTransform::Registry`
    - `register(transform_class)`
    - `apply_all(block, direction:, format:) → block` (returns new block)
- `coradoc/spec/core_model/frontmatter/field_transform_spec.rb`

## Built-in transforms

Registered by `coradoc-markdown` (since it's Markdown-specific):

- `AuthorsToAuthorTransform` — applies when direction=`:to_format`,
  format=`:markdown`. Collapses `authors` array-of-maps to a single
  `author` string joined by `, `.
- `DropLayoutTransform` — drops `layout` key (Jekyll-specific) when
  emitting Markdown.

## Behavior

- Transforms are applied in registration order.
- Each transform sees the block, may add/remove/modify entries, returns
  the (possibly new) block.
- `apply_all` always returns a `FrontmatterBlock`; never mutates the input
  (immutability principle).

## Out of scope

- Codec (TODO 03)
- Schema validation (TODO 04)

## Status

Implemented (registry + the two Markdown-specific transforms).
