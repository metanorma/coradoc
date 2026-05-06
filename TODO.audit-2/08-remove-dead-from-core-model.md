# TODO 08: Remove dead code from FromCoreModel

Status: DONE

## Problem
`FromCoreModel#transform_with_case` (44 lines) is dead code. All CoreModel types are registered
via `FromCoreModelRegistrations`, so the case-statement fallback is never reached.

## Files
- `coradoc-adoc/lib/coradoc/asciidoc/transform/from_core_model.rb` — remove lines 42-86
- `coradoc-adoc/spec/coradoc/asciidoc/transform/from_core_model_spec.rb` — add spec for error

## Changes
1. Remove `transform_with_case` method entirely
2. In `transform`, raise `TransformationError` instead of falling back
3. Add spec verifying `TransformationError` is raised for unregistered types
