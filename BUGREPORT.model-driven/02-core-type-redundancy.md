# 02: Quadruple redundancy of block type information

## Status: FIXED

- `BlockSemanticType` module removed entirely
- `element_type` attribute removed from `Block` (now a derived method via class hierarchy)
- `block_semantic_type` retained only on generic `Block` instances for untyped blocks
- `resolve_semantic_type` simplified to check class hierarchy first, then fall back to `block_semantic_type`


**Severity:** HIGH  
**Location:** `lib/coradoc/core_model/block.rb`, all typed block subclasses

## Problem

Block type identity is expressed in **five** independent ways — four within CoreModel, one in the class hierarchy. This creates confusion about which API to use and makes adding new block types error-prone.

The five expressions of "this is a source code block":
1. **Class:** `SourceBlock < Block` — the class IS the type
2. **`self.semantic_type`:** returns `:source_code` (symbol)
3. **`block_semantic_type`:** defaults to `'source_code'` (string — inconsistent with symbol above)
4. **`element_type`:** sometimes set to string like `'paragraph'`
5. **`BlockSemanticType::SOURCE_CODE`:** constant `= :source_code`

## Evidence

### 2A. Every typed subclass repeats the same value twice

| File | Line | `self.semantic_type` | `block_semantic_type` default |
|------|------|---------------------|-------------------------------|
| `source_block.rb` | 17, 19 | `:source_code` | `'source_code'` |
| `quote_block.rb` | 7, 9 | `:quote` | `'quote'` |
| `example_block.rb` | 7, 9 | `:example` | `'example'` |
| `sidebar_block.rb` | 7, 9 | `:sidebar` | `'sidebar'` |
| `literal_block.rb` | 7, 9 | `:literal` | `'literal'` |
| `open_block.rb` | 7, 9 | `:open` | `'open'` |
| `pass_block.rb` | 7, 9 | `:pass` | `'pass'` |
| `verse_block.rb` | 7, 9 | `:verse` | `'verse'` |
| `listing_block.rb` | 10, 12 | `:listing` | `'listing'` |
| `reviewer_block.rb` | 7, 9 | `:reviewer` | `'reviewer'` |

Example from `source_block.rb`:
```ruby
class SourceBlock < Block
  def self.semantic_type = :source_code
  attribute :block_semantic_type, :string, default: -> { 'source_code' }
end
```

### 2B. Four-level fallback chain in `resolve_semantic_type`
`lib/coradoc/core_model/block.rb:73-77`:
```ruby
def resolve_semantic_type
  self.class.semantic_type ||
    (block_semantic_type&.to_sym) ||
    resolve_semantic_from_element_type ||
    resolve_semantic_from_delimiter
end
```

### 2C. `BlockSemanticType` module — a FIFTH expression
`lib/coradoc/core_model/block.rb:10-32`:
```ruby
module BlockSemanticType
  SOURCE_CODE = :source_code
  LISTING = :listing
  EXAMPLE = :example
  # ... 16 constants total
end
```
Constants like `HORIZONTAL_RULE`, `VIDEO`, `AUDIO`, `COMMENT` have no corresponding subclasses.

### 2D. `element_type` — a SIXTH expression on Block
`lib/coradoc/core_model/block.rb:87`:
```ruby
attribute :element_type, :string
```
Used for string-based dispatch in format gems instead of class checks.

## Fix

1. Remove `block_semantic_type` attribute from typed subclasses — the class IS the type.
2. Remove `element_type` from `Block` — use the class hierarchy.
3. Remove `BlockSemanticType` constants — derive from `self.semantic_type` on subclasses.
4. Simplify `resolve_semantic_type` to just `self.class.semantic_type`.
5. Keep `block_semantic_type` only on the generic `Block` class for truly generic instances.
