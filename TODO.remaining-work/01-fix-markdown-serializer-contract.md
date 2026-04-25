# 01 — Fix Markdown Serializer Error-Handling Contract

**Status**: PENDING
**Priority**: P1
**Effort**: Small

## Problem

CLAUDE.md mandates: *"Unknown types in `serialize_content` should raise `ArgumentError`, never fall back to `to_s`."* Two violations exist in the Markdown gem:

1. `coradoc-markdown/lib/coradoc/markdown/model/base.rb:62` — `serialize_content` falls back to `to_s`:
   ```ruby
   content.respond_to?(:to_md) ? content.to_md : content.to_s
   ```

2. `coradoc-markdown/lib/coradoc/markdown/serializer.rb:69-70` — raises generic `RuntimeError` instead of `ArgumentError`:
   ```ruby
   raise "Unknown element type for serialization: #{element.class}"
   ```

3. `coradoc-markdown/lib/coradoc/markdown/serializer.rb:99` — `serialize_inline_content` also falls back to `to_s`.

These produce silent Ruby object dumps (`#<Object:0x...>`) instead of failing fast with a clear error.

## Model-Driven Approach

The serializer contract is: each model type owns its `to_md` serialization. When an unrecognized object enters the serialization pipeline, it is a **model-level bug** (missing model or missing `to_md`), not a serializer concern. Raising `ArgumentError` catches these at the boundary.

## Scope

- Change `serialize_content` in `model/base.rb` to raise `ArgumentError` for unknown types
- Change `Serializer.serialize_inline_content` to raise `ArgumentError` for unknown types
- Change `Serializer` dispatch to raise `ArgumentError` instead of `RuntimeError`
- Add specs for each error-raising path

## Acceptance Criteria

- [ ] `serialize_content` raises `ArgumentError` for non-String objects without `to_md`
- [ ] `Serializer` raises `ArgumentError` for unrecognized element types
- [ ] `serialize_inline_content` raises `ArgumentError` for unrecognized inline types
- [ ] All existing specs pass
- [ ] New specs cover all three error-raising paths
