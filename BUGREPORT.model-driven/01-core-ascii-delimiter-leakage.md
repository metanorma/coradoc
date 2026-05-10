# 01: AsciiDoc delimiter mappings hardcoded in CoreModel

## Status: FIXED

- `DELIMITER_CHAR_TO_SEMANTIC` constant removed from `CoreModel::Block`
- `delimiter_to_semantic_type` method removed from `BlockBuilder`
- `delimiter_type` attribute retained on `Block` for format-specific round-trip serialization (correct design)


**Severity:** CRITICAL  
**Location:** `lib/coradoc/core_model/block.rb`, `lib/coradoc/core_model/builder/block_builder.rb`

## Problem

CoreModel is the format-neutral hub, yet it contains hardcoded AsciiDoc delimiter-to-semantics mappings in TWO places. The characters `-`, `=`, `_`, `*`, `.`, `+` and the convention of 4-character delimiters are AsciiDoc-specific. Markdown uses fences (```), HTML uses tags (`<pre>`, `<blockquote>`). This knowledge has no place in the core.

## Evidence

### 1A. `DELIMITER_CHAR_TO_SEMANTIC` constant
`lib/coradoc/core_model/block.rb:134-141`:
```ruby
DELIMITER_CHAR_TO_SEMANTIC = {
  '-' => :source_code,
  '=' => :example,
  '_' => :quote,
  '*' => :sidebar,
  '.' => :literal,
  '+' => :pass
}.freeze
```

### 1B. `resolve_semantic_from_delimiter` method
`lib/coradoc/core_model/block.rb:125-131`:
```ruby
def resolve_semantic_from_delimiter
  delim = delimiter_type
  return nil unless delim && delim.length >= 4
  char = delim[0]
  DELIMITER_CHAR_TO_SEMANTIC[char] || nil
end
```
The assumption that delimiters are ≥4 chars and the first char determines the type is an AsciiDoc parsing rule.

### 1C. `delimiter_to_semantic_type` in BlockBuilder — DUPLICATE of 1A
`lib/coradoc/core_model/builder/block_builder.rb:45-58`:
```ruby
def delimiter_to_semantic_type(delimiter)
  return nil unless delimiter && !delimiter.empty?
  char = delimiter[0]
  case char
  when '-' then :source_code
  when '=' then :example
  when '_' then :quote
  when '*' then :sidebar
  when '.' then :literal
  when '+' then :pass
  else nil
  end
end
```
Same mapping, different implementation — duplicated within CoreModel itself.

### 1D. `delimiter_type` attribute — DEPRECATED but still used
`lib/coradoc/core_model/block.rb:90-93`:
```ruby
# DEPRECATED — use block_semantic_type. Retained for backward compatibility.
attribute :delimiter_type, :string
```
Still read by `resolve_semantic_from_delimiter` at line 126.

### 1E. `delimiter_length` attribute — AsciiDoc convention
`lib/coradoc/core_model/block.rb:95-97`:
```ruby
attribute :delimiter_length, :integer, default: -> { 4 }
```
"Number of delimiter characters" defaulting to 4 is the AsciiDoc convention.

### 1F. BlockBuilder sets `delimiter_length`
`lib/coradoc/core_model/builder/block_builder.rb:20,35`:
```ruby
delimiter_length: ast[:delimiter]&.to_s&.length || 4,
```

## Fix

1. Remove `DELIMITER_CHAR_TO_SEMANTIC`, `resolve_semantic_from_delimiter`, `delimiter_type`, `delimiter_length` from `CoreModel::Block`.
2. Remove `delimiter_to_semantic_type` from `BlockBuilder`.
3. Move all delimiter-to-semantics mapping to `coradoc-adoc`'s ToCoreModel transformer, which should resolve the semantic type before constructing CoreModel objects.
