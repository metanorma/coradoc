# 08 — HTML / DOCX Frontmatter Integration

## Goal

Map `FrontmatterBlock` to HTML `<meta>` tags and DOCX core properties so
the same CoreModel metadata flows to every output format.

## Why

- Confirms the architecture is truly format-agnostic.
- HTML/DOCX consumers benefit from the same metadata without writing
  bespoke mappers.

## HTML mapping

- `title` → `<title>`
- `author` → `<meta name="author">`
- `description`/`excerpt` → `<meta name="description">`
- `date` → `<meta name="date">` (ISO 8601)
- `tags`/`categories` → `<meta name="keywords">` (comma-joined)
- Other scalar entries → `<meta name="X">`
- Array entries → one `<meta>` per item (with multi-valued attribute)
- `$schema` → `<link rel="schema">` (if resolvable)

## DOCX mapping (core properties)

- `title` → `dc:title`
- `author` → `dc:creator`
- `date` → `dc:date`
- `description`/`excerpt` → `dc:description`
- `tags` → `cp:keywords`

## Files (deferred)

- `coradoc-html/lib/coradoc/html/converter_base.rb` — FrontmatterBlock →
  meta tags via Nokogiri builder
- `coradoc-docx/lib/coradoc/docx/transformer.rb` — FrontmatterBlock →
  core properties

## Status

TODO — architecture is ready; only the format-specific emission code is
needed. Each is a small, self-contained addition once the HTML/DOCX
converters learn to dispatch on `FrontmatterBlock`.
