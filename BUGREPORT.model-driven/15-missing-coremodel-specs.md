# 15: 14 CoreModel typed Block subclasses have no specs

## Status: NOT FIXED

- 14 of 34 CoreModel classes lack dedicated spec files
- Typed block subclasses define `semantic_type` but have no test coverage


**Severity:** MEDIUM
**Location:** `spec/core_model/`

## Missing Specs

| Class | File |
|-------|------|
| `CommentBlock` | `lib/coradoc/core_model/comment_block.rb` |
| `ExampleBlock` | `lib/coradoc/core_model/example_block.rb` |
| `HorizontalRuleBlock` | `lib/coradoc/core_model/horizontal_rule_block.rb` |
| `ListingBlock` | `lib/coradoc/core_model/listing_block.rb` |
| `LiteralBlock` | `lib/coradoc/core_model/literal_block.rb` |
| `OpenBlock` | `lib/coradoc/core_model/open_block.rb` |
| `ParagraphBlock` | `lib/coradoc/core_model/paragraph_block.rb` |
| `PassBlock` | `lib/coradoc/core_model/pass_block.rb` |
| `QuoteBlock` | `lib/coradoc/core_model/quote_block.rb` |
| `ReviewerBlock` | `lib/coradoc/core_model/reviewer_block.rb` |
| `SidebarBlock` | `lib/coradoc/core_model/sidebar_block.rb` |
| `SourceBlock` | `lib/coradoc/core_model/source_block.rb` |
| `VerseBlock` | `lib/coradoc/core_model/verse_block.rb` |
| `DefinitionItem` | `lib/coradoc/core_model/definition_item.rb` |

## Fix

Create a single spec file `spec/core_model/typed_blocks_spec.rb` covering all typed block subclasses. Each should test:
- Inherits from `Block`
- `semantic_type` returns the correct symbol
- `element_type` returns the correct string
- Can be instantiated with content/attributes
- `comparable_attributes` works correctly
