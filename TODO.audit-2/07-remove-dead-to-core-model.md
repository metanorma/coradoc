# TODO 07: Remove dead code from ToCoreModel

Status: DONE

## Problem
`ToCoreModel#transform_with_case` (83 lines) and `determine_block_type` (20 lines) are dead code.
All AsciiDoc model types are registered via `ToCoreModelRegistrations`, so the case-statement
fallback is never reached. `determine_block_type` is never called anywhere.

## Files
- `coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb` — remove lines 42-147
- `coradoc-adoc/spec/coradoc/asciidoc/transform/to_core_model_spec.rb` — add spec for error on unregistered type

## Changes
1. Remove `transform_with_case` method entirely
2. Remove `determine_block_type` method entirely
3. In `transform`, raise `TransformationError` instead of falling back to case statement
4. Add spec verifying `TransformationError` is raised for unregistered types
