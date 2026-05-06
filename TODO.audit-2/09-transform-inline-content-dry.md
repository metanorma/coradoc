# TODO 09: Eliminate DRY violation in transform_inline_content

Status: DONE

## Problem
Inline types are known in FOUR places: registrations, transform_with_case (dead),
transform_inline_content (70 lines of duplication), and extract_text_content (77 lines).
Adding a new inline type requires updating all four. Worse, transform_inline_content
has subtle bugs vs registered transformers:
- Link: missing `|| content.path` fallback for content
- Stem: missing `stem_type` attribute

## Files
- `coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb` — refactor transform_inline_content

## Changes
1. Refactor `transform_inline_content` to delegate to `transform()` via Registry for all
   AsciiDoc model types, keeping only structural cases (String, Array, TextElement)
2. Fix Link content fallback and Stem stem_type in registered transformers
3. Register Inline::AttributeReference if used in inline content
