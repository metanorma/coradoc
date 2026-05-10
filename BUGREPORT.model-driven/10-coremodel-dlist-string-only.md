# 10: CoreModel DefinitionItem stores only strings — cannot hold structured content

## Status: FIXED

- `DefinitionItem` has `term_children` and `definition_children` for structured content (arrays of mixed `String` + `InlineElement`)
- `term_renderable` and `definition_renderable` methods provide mixed content access (following `Block#renderable_content` pattern)
- `term` and `definitions` attributes remain `:string` for backward compatibility
- ToCoreModel transformer populates both flat string and structured children arrays
- `term_children` and `definition_children` now included in `comparable_attributes` for equality checking


**Severity:** HIGH
**Location:** `lib/coradoc/core_model/definition_item.rb`, `lib/coradoc/core_model/definition_list.rb`

## Test file

`/Users/mulgogi/src/chinese/cham-format/sections/03-terms.adoc` — definition list entries like `[[term-cham-file]]CHAM file:: A thing. See <<file-format>>.`

## Problem

`CoreModel::DefinitionItem` declares `term` as `:string` and `definitions` as `:string, collection: true`. These fields can only hold flat text — they cannot carry `InlineElement` children for anchors, cross-references, or monospace formatting. This is the same architectural gap that `Block` solved via the `ChildrenContent` module, but `DefinitionItem` does not include it.

Meanwhile, the ToCoreModel transformer actively discards inline structure by calling `extract_text_content` instead of `transform_inline_content`.

## Evidence

### 10A. DefinitionItem has no children support

`lib/coradoc/core_model/definition_item.rb:14-15`:
```ruby
class DefinitionItem < Base
  attribute :term, :string
  attribute :definitions, :string, collection: true
end
```

No `include ChildrenContent`. No `children` array. The class inherits from `Base` directly.

### 10B. Block has children support — the pattern to follow

`lib/coradoc/core_model/block.rb:58-59`:
```ruby
class Block < Base
  include ChildrenContent
```

`lib/coradoc/core_model/children_content.rb:31-36`:
```ruby
def renderable_content
  return content if children.nil? || children.none?
  return content if content && children.all?(String)
  children
end
```

Block can carry both a `content` string (for simple text) and a `children` array (for mixed strings + InlineElements). `renderable_content` prefers children when they contain non-string objects.

### 10C. ToCoreModel collapses definition list structure to strings

`coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb:229-236`:
```ruby
Coradoc::CoreModel::DefinitionItem.new(
  term: extract_text_content(term_content),
  definitions: [extract_text_content(def_content)]
)
```

`extract_text_content` (line 457) recursively flattens everything to a string. Compare with the regular list item path just below it (line 239-246):

```ruby
content_val = item.content
children = transform_inline_content(content_val)

li = Coradoc::CoreModel::ListItem.new(
  content: extract_text_content(content_val),
  marker: item.marker
)
li.children = children
```

Regular list items call both `extract_text_content` (for the flat text fallback) AND `transform_inline_content` (for structured children). Definition items only call `extract_text_content`.

### 10D. ToCoreModel collapses admonition content to string

`coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb:274-278`:
```ruby
def transform_admonition(admonition)
  CoreModel::AnnotationBlock.new(
    annotation_type: admonition.type,
    content: extract_text_content(admonition.content)
  )
end
```

Same pattern — `extract_text_content` instead of `transform_inline_content`. The resulting `AnnotationBlock` (which extends `Block` and therefore HAS `children`) gets a `content` string but empty `children`, so `renderable_content` returns the flat string. No inline elements survive.

### 10E. Confirmed CoreModel output

Parsing `[[term-cham-file]]CHAM file:: A thing. See <<file-format>>.` produces:
```
DefinitionItem: term="[[term-cham-file]]CHAM file" defs=["A thing. See <<file-format>>."]
```

Flat strings throughout. No `InlineElement` instances for the anchor or cross-reference.

## Impact

Even if the AsciiDoc parser (report 09) is fixed to produce structured model objects for definition list content, the CoreModel cannot store them. The `term` attribute rejects non-string values. The `definitions` attribute rejects non-string values.

For admonitions, the CoreModel (`AnnotationBlock < Block`) can technically hold children, but the ToCoreModel transformer never populates them — it only sets the flat `content` string.

## Fix

1. **DefinitionItem**: Add `include ChildrenContent` or equivalent support for storing inline elements alongside the term text. Consider separate children arrays for term and definitions, since term and definitions are independent content areas.

   One approach: add `term_children` and `definition_children` attributes (arrays of mixed String + InlineElement), with a `term_renderable` method that follows the same pattern as `Block#renderable_content`.

   Another approach: model the term as a `CoreModel::Term` object that itself has structured content, and store definition content similarly to how `Block` does.

2. **ToCoreModel transformer**: For definition items, call `transform_inline_content` on term content and definition content, and populate the children arrays. Follow the same pattern used for `ListItem` (line 239-246).

3. **ToCoreModel transformer**: For admonitions, call `transform_inline_content` on admonition content and set the `children` array on the resulting `AnnotationBlock`. The `AnnotationBlock` already extends `Block` which includes `ChildrenContent`, so no model change is needed — only the transformer needs to populate `children`.
