# 08: Markdown FromCoreModel returns raw strings instead of model instances

## Status: FIXED

- Markdown `FromCoreModel#transform_inline` now returns model instances for all inline element types (subscript, superscript, underline, xref)
- Proper Markdown model classes handle string representation via the serializer layer


**Severity:** LOW  
**Location:** `coradoc-markdown/lib/coradoc/markdown/transform/from_core_model.rb`

## Problem

The Markdown `FromCoreModel#transform_inline` method returns raw HTML/Markdown strings for four inline element types instead of proper Markdown model instances. This bypasses the serializer layer and breaks the model pipeline.

## Evidence

`from_core_model.rb:258-264`:
```ruby
when 'subscript'
  "<sub>#{element.content}</sub>"       # raw HTML string
when 'superscript'
  "<sup>#{element.content}</sup>"       # raw HTML string
when 'underline'
  "<u>#{element.content}</u>"           # raw HTML string
when 'xref'
  "[#{element.content}](##{element.target})"  # raw Markdown string
```

Other inline types in the same method correctly return `Coradoc::Markdown::*` model instances.

## Fix

Create proper Markdown model classes for `Subscript`, `Superscript`, `Underline`, and `Xref` (or add these types to existing inline model classes). Return model instances from the FromCoreModel transformer and let the serializer handle the string representation.
