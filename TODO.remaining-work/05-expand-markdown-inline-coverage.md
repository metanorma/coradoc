# 05 — Expand Markdown Inline Format Coverage

**Status**: PENDING
**Priority**: P2
**Effort**: Medium

## Problem

The Markdown `ToCoreModel` handles only 6 inline types (italic, bold, monospace, link, stem, footnote). Six types that survive AsciiDoc→CoreModel conversion are silently dropped in Markdown:

| CoreModel format_type | Markdown support |
|---|---|
| `highlight` | **MISSING** — `==text==` in some Markdown flavors |
| `strikethrough` | **MISSING** — `~~text~~` is GFM standard |
| `subscript` | **MISSING** — no standard Markdown syntax |
| `superscript` | **MISSING** — no standard Markdown syntax |
| `underline` | **MISSING** — no standard Markdown syntax |
| `xref` | **MISSING** — no Markdown equivalent |

Similarly, the Markdown `FromCoreModel` only handles bold, italic, monospace, link, footnote, and stem. It drops highlight, strikethrough, subscript, superscript, and underline.

## Model-Driven Approach

Follow the existing model-driven pattern:
1. **ToCoreModel**: Add inline type dispatch cases in `coradoc-markdown/lib/coradoc/markdown/transform/to_core_model.rb` for existing Markdown model types that map to the missing CoreModel types (e.g., Strikethrough → `format_type: 'strikethrough'`)
2. **FromCoreModel**: Add dispatch cases in `from_core_model.rb` that produce the corresponding Markdown model types

For types with no standard Markdown syntax (subscript, superscript, underline), fall back to plain text or use HTML passthrough (`<sub>`, `<sup>`, `<u>`) if the Markdown model supports it. The decision should be encapsulated in the FromCoreModel transformer, not in the CoreModel.

## Scope

- Extend `Markdown::Transform::ToCoreModel` for Strikethrough and any other inline types present in the Markdown model
- Extend `Markdown::Transform::FromCoreModel` to handle highlight, strikethrough (GFM `~~`), subscript/superscript/underline (HTML fallback or plain text)
- Add specs for each new inline type in both directions
- Test cross-format round-trip: ADoc → CoreModel → MD → CoreModel → ADoc for inline elements

## Acceptance Criteria

- [ ] Markdown ToCoreModel handles all inline types present in the Markdown model
- [ ] Markdown FromCoreModel produces appropriate output for highlight, strikethrough
- [ ] Subscript, superscript, underline are handled (even if degraded to plain text or HTML)
- [ ] Cross-format round-trip specs verify inline preservation
- [ ] All existing specs pass
