# 02 — Fix AsciiDoc Serializer Top-Level Dispatch Contract

**Status**: PENDING
**Priority**: P1
**Effort**: Small

## Problem

The AsciiDoc gem's model-level `serialize_content` correctly raises `ArgumentError` for unknown types, and `Serializers::Base` does too. However, the top-level `AdocSerializer.serialize` at `coradoc-adoc/lib/coradoc/asciidoc/serializer/adoc_serializer.rb:39-41` silently returns empty string for unknown types:

```ruby
else
  model.respond_to?(:to_str) ? model.to_s : ''
end
```

This silently drops unrecognized model objects instead of failing fast.

## Model-Driven Approach

The AsciiDoc serializer uses an `ElementRegistry` where each model type has a dedicated serializer class. If a model type has no registered serializer, that's a **registration gap** — the fix is to register the serializer, not silently discard the content. Raising `ArgumentError` surfaces the gap immediately.

## Scope

- Change `AdocSerializer.serialize` to raise `ArgumentError` for unrecognized non-String types
- Verify existing specs still pass (this may surface previously-hidden gaps)
- Add specs for the error-raising path

## Acceptance Criteria

- [ ] `AdocSerializer.serialize` raises `ArgumentError` for unrecognized model types
- [ ] `String` and `Parslet::Slice` still serialize correctly (these are valid leaf types)
- [ ] All existing specs pass
