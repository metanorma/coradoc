# 05: CoreModel Builder encodes format-specific parsing knowledge

## Status: FIXED

- Builder methods now return typed CoreModel objects (ParagraphBlock, SectionElement, HeaderElement, CommentBlock, Table, BibliographyEntry, ElementAttribute) instead of raw Hashes
- `group_document_elements` uses `is_a?` class checks instead of Hash `[:type]` discrimination
- `build_attributes` returns `ElementAttribute` typed objects
- Detection logic (marker types, inline format detection) remains AsciiDoc-specific as it lives under `coradoc-adoc/`
- `document_builder.rb` in core remains format-neutral


**Severity:** HIGH  
**Location:** `lib/coradoc/core_model/builder/` (all files)

## Problem

The `Builder` class lives under `lib/coradoc/core_model/builder/` but contains AsciiDoc-specific parsing logic throughout. The Builder should be format-neutral — it is part of CoreModel.

## Evidence

### 5A. `detect_marker_type` maps AsciiDoc markers to names
`lib/coradoc/core_model/builder/detection.rb:107-115`:
```ruby
def detect_marker_type(ast)
  marker = ast[:marker]&.to_s
  return 'asterisk' if marker&.start_with?('*')
  return 'dash' if marker&.start_with?('-')
  return 'numbered' if marker&.match?(/^\d+\./) || marker&.start_with?('.')
  return 'labeled' if marker&.end_with?('::')
  'asterisk'
end
```
`::` for labeled lists is purely AsciiDoc. The default `'asterisk'` is AsciiDoc's default. Markdown uses `-`, `*`, `+` for unordered and `1.` for ordered — no "labeled" type.

### 5B. `detect_marker_level` counts AsciiDoc marker repetition
`lib/coradoc/core_model/builder/detection.rb:117-122`:
```ruby
def detect_marker_level(ast)
  marker = ast[:marker]&.to_s
  return marker.length if marker&.match?(/^[*.]+$/)
  1
end
```
Nesting level encoded by marker repetition (`*` = level 1, `**` = level 2) is AsciiDoc. Markdown encodes nesting via indentation.

### 5C. `extract_level` decodes `=` prefixed levels
`lib/coradoc/core_model/builder/detection.rb:157-165`:
```ruby
def extract_level(ast)
  if ast[:level]
    level_str = ast[:level].to_s
    return level_str.length - 1 if level_str.start_with?('=')
    return level_str.to_i if level_str.match?(/^\d+$/)
  end
  1
end
```
Decoding heading level from `=` count (`==` = level 2) is AsciiDoc ATX-style heading syntax.

### 5D. `list_markers` hardcodes AsciiDoc markers
`lib/coradoc/core_model/builder/detection.rb:172-175`:
```ruby
def list_markers
  %w[* - . :: numbered]
end
```

### 5E. `extract_annotation_type` checks AsciiDoc-specific AST
`lib/coradoc/core_model/builder/detection.rb:67-87`:
```ruby
def extract_annotation_type(ast)
  attr_list = ast[:attribute_list]
  if attr_list.is_a?(Hash) && attr_list[:positional]
    positional = Array(attr_list[:positional])
    annotation = positional.find do |p|
      annotation_types.include?(p.to_s.downcase)
    end
    return annotation.to_s.downcase if annotation
  end
  return ast[:admonition_type]&.to_s&.downcase if ast[:admonition_type]
```
`attribute_list[:positional]` for `[NOTE]` syntax and `admonition_type` are AsciiDoc AST concepts.

### 5F. Builder methods return raw Hashes, not CoreModel objects
`lib/coradoc/core_model/builder.rb:179-189`:
```ruby
def build_paragraph(ast)
  {
    type: :paragraph,
    content: build_paragraph_content(para_ast[:lines]),
  }
end
```
Many builder methods return plain Hashes instead of typed CoreModel objects, undermining the purpose of having typed models.

## Fix

Relocate the Builder from `core_model/builder/` to the format gems. Only format-neutral construction logic should remain in CoreModel. The AsciiDoc gem should own its own builder that knows about AsciiDoc AST structure.
