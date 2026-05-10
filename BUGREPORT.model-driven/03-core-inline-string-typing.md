# 03: InlineElement string-based format_type vs Block subclass pattern

## Status: FIXED

- Typed `InlineElement` subclasses created: `BoldElement`, `ItalicElement`, `MonospaceElement`, `UnderlineElement`, `StrikethroughElement`, `SubscriptElement`, `SuperscriptElement`, `HighlightElement`, `LinkElement`, `XrefElement`, `StemElement`, `FootnoteElement`, `HardLineBreakElement`
- `FORMAT_TYPE_CLASS_MAP` hash added for string-to-class lookup (backward compatibility)
- `constrained` attribute removed from `InlineElement` (AsciiDoc-only concept)
- Two divergent type lists consolidated into single canonical source on `InlineElement`


**Severity:** HIGH  
**Location:** `lib/coradoc/core_model/inline_element.rb`, `lib/coradoc/core_model/builder/detection.rb`

## Problem

`CoreModel::InlineElement` uses a `format_type` string attribute (`'bold'`, `'italic'`, `'monospace'`) to distinguish inline types, while `Block` correctly uses typed subclasses (`SourceBlock < Block`, `QuoteBlock < Block`). This architectural inconsistency forces every consumer to use `case format_type` instead of polymorphic dispatch.

Additionally, the `constrained` attribute on `InlineElement` is an AsciiDoc-only concept.

## Evidence

### 3A. String-based `format_type` with divergent type lists
`lib/coradoc/core_model/inline_element.rb:49-61`:
```ruby
FORMAT_TYPES = %w[
  bold italic monospace underline strikethrough
  subscript superscript highlight
  link xref stem footnote
  hard_line_break
].freeze

attribute :format_type, :string
```

The Builder's `Detection#inline_format_types` (`builder/detection.rb:178-183`) defines a DIFFERENT list:
```ruby
%i[bold italic monospace superscript subscript highlight span link
   cross_reference bold_constrained bold_unconstrained
   italic_constrained italic_unconstrained monospace_constrained
   monospace_unconstrained]
```

Divergence:
- `FORMAT_TYPES` has: `underline`, `strikethrough`, `xref`, `stem`, `footnote`, `hard_line_break`
- `inline_format_types` has: `span`, `cross_reference`, `*_constrained`, `*_unconstrained`
- `xref` vs `cross_reference` — two names for the same concept
- Strings vs symbols inconsistency

### 3B. Cascading `case`/`when` chains in every transformer
- `coradoc-html/lib/coradoc/html/converters/base.rb:109-152` — 20-case chain
- `coradoc-adoc/lib/coradoc/asciidoc/transform/from_core_model.rb:225-260` — 15-case chain
- `coradoc-markdown/lib/coradoc/markdown/transform/from_core_model.rb:172-206` — 15-case chain
- `coradoc-docx/lib/coradoc/docx/transform/from_core_model.rb:43-57` — catches all InlineElement then re-dispatches

### 3C. `constrained` attribute — AsciiDoc-only concept
`lib/coradoc/core_model/inline_element.rb:63-66`:
```ruby
# whether the formatting uses constrained syntax (true for *text*, false for **text**)
attribute :constrained, :boolean, default: -> { true }
```
Constrained/unconstrained is uniquely AsciiDoc. Markdown uses `*` vs `**` for italic vs bold — a different semantic. HTML has no such concept.

### 3D. Builder detection of `_constrained`/`_unconstrained` AST keys
`lib/coradoc/core_model/builder/detection.rb:126-153`:
```ruby
def detect_inline_format(ast)
  ast.each_key do |key|
    key_str = key.to_s
    return key_str if key_str.end_with?('_constrained', '_unconstrained')
  end
end

def detect_constrained(ast, format_type)
  if format_type.end_with?('_constrained')
    return true
  elsif format_type.end_with?('_unconstrained')
    return false
  end
end
```
These AST key names are artifacts of the AsciiDoc parser's AST structure.

## Fix

1. Create typed InlineElement subclasses matching the Block pattern: `BoldElement`, `ItalicElement`, `LinkElement`, etc.
2. Move `constrained` to the AsciiDoc format gem's own inline model.
3. Consolidate the two divergent type lists into a single canonical source.
4. Transformers use class-based dispatch (`when Coradoc::CoreModel::BoldElement`) instead of string matching.
