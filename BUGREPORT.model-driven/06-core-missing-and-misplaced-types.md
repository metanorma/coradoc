# 06: Missing types, duplicate definitions, and misplaced concepts in CoreModel

## Status: FIXED

- `StructuralElement` subclasses created: `DocumentElement`, `SectionElement`, `PreambleElement`, `HeaderElement`
- `element_type` removed from `StructuralElement` (now a derived method via class hierarchy)
- `ListBlock` duplicate definition resolved
- `marker_type` uses semantic terms (`unordered`, `ordered`, `definition`) instead of AsciiDoc vocabulary
- `ParagraphBlock`, `CommentBlock`, `HorizontalRuleBlock` subclasses created


**Severity:** MEDIUM  
**Location:** Multiple CoreModel files

## Problem

CoreModel has several structural issues: missing subclass types that are defined as constants but never implemented, duplicate class definitions that create runtime ambiguity, and attributes using format-specific vocabulary instead of semantic terms.

## Evidence

### 6A. `StructuralElement` uses string-based `element_type` instead of subclasses
`lib/coradoc/core_model/structural_element.rb:40-43,67-74`:
```ruby
attribute :element_type, :string

def section?
  element_type == 'section'
end

def document?
  element_type == 'document'
end
```
Same anti-pattern as `InlineElement.format_type`. Should have `Section`, `Document`, `Preamble` subclasses matching the Block pattern.

### 6B. `ListBlock.marker_type` uses AsciiDoc vocabulary
`lib/coradoc/core_model/list_block.rb:95-98`:
```ruby
attribute :marker_type, :string
# values: 'asterisk', 'dash', 'numbered', 'labeled'
```
`'asterisk'` and `'labeled'` are AsciiDoc vocabulary. Format-neutral terms should be `'unordered'`, `'ordered'`, `'definition'`. The specific marker character is a rendering detail.

### 6C. `ListItem.marker` stores raw format-specific marker strings
`lib/coradoc/core_model/list_item.rb:29`:
```ruby
attribute :marker, :string
```
The raw marker character (`"*"`, `"**"`, `"::"`) is AsciiDoc-specific.

### 6D. No `Paragraph` class
`BlockSemanticType::PARAGRAPH = :paragraph` exists but there is no `ParagraphBlock` subclass. Paragraphs are represented as `Block` with `block_semantic_type: 'paragraph'` — string-based.

### 6E. No `CommentBlock` subclass
`BlockSemanticType::COMMENT = :comment` exists but no subclass.

### 6F. No subclasses for `VIDEO`, `AUDIO`, `HORIZONTAL_RULE`
`BlockSemanticType` defines constants for these but they have no implementations.

### 6G. Duplicate `ListBlock` definitions
`lib/coradoc/core_model/list_block.rb` and `lib/coradoc/core_model/list_item.rb` both define `ListBlock` with different attributes:
- `list_block.rb`: `marker_type`, `marker_level`, `start`, `items`
- `list_item.rb`: `marker_type`, `marker_level`, `items` (no `start`)

The class that gets loaded depends on autoload order.

### 6H. Comments reference specific formats
- `inline_element.rb:7`: "Represents all inline text formatting in AsciiDoc:"
- `list_item.rb:5`: "Represents a list item in AsciiDoc"
- `list_block.rb:58`: "Handles all AsciiDoc list types:"
- `bibliography.rb:8`: "typically marked with [bibliography] attribute in AsciiDoc"
- `definition_list.rb:8`: "This maps to Kramdown definition lists and AsciiDoc labeled lists"

## Fix

1. Create typed subclasses where constants exist but implementations don't (Paragraph, Comment, etc.)
2. Remove duplicate `ListBlock` from `list_item.rb`
3. Rename `marker_type` values from AsciiDoc vocabulary to semantic terms
4. Make `StructuralElement` use subclasses instead of string `element_type`
5. Update comments to be format-neutral
