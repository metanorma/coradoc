# TODO 12: Add missing spec coverage

Status: DONE

## Problem
Critical paths lack direct unit test coverage:
- `transform_inline_content` — only tested indirectly via paragraph transform
- `extract_text_content` — no direct specs
- ToCoreModel/FromCoreModel error on unregistered types — no specs
- DocumentBuilder edge cases — missing to_asciidoc, error on item outside list
- FromCoreModel#transform_inline format_type exhaustiveness — not tested

## Files
- `coradoc-adoc/spec/coradoc/asciidoc/transform/to_core_model_spec.rb`
- `coradoc-adoc/spec/coradoc/asciidoc/transform/from_core_model_spec.rb`
- `spec/coradoc/document_builder_spec.rb`

## Changes
1. Add direct unit specs for `transform_inline_content` with each inline type
2. Add direct unit specs for `extract_text_content` with each content type
3. Add specs for TransformationError on unregistered types
4. Add DocumentBuilder edge case specs
