# 04: HTML-specific attributes in CoreModel

## Status: FIXED

- `bgcolor`, `color`, `width`, `height` removed from `TableCell`
- `frame` removed from `Table`
- `caption` retained on `Image` (format-neutral concept, not HTML-specific)
- `width`/`height` retained on `Image` (used by both AsciiDoc and HTML output)


**Severity:** MEDIUM  
**Location:** `lib/coradoc/core_model/table.rb`, `lib/coradoc/core_model/image.rb`

## Problem

CoreModel carries CSS/HTML-specific attributes that the comments explicitly mark as "HTML converter only". These attributes are meaningless for AsciiDoc, Markdown, and DOCX formats.

## Evidence

### 4A. TableCell: `bgcolor`, `color`, `width`, `height` — marked "HTML converter only"
`lib/coradoc/core_model/table.rb:53-71`:
```ruby
# @note Populated by HTML converter only
attribute :bgcolor, :string

# @note Populated by HTML converter only
attribute :color, :string

# @note Populated by HTML converter only
attribute :width, :string

# @note Populated by HTML converter only
attribute :height, :string
```

### 4B. Table: `frame` — marked "HTML converter only"
`lib/coradoc/core_model/table.rb:149-152`:
```ruby
# @note Populated by HTML converter only
attribute :frame, :string
```

### 4C. Image: `caption` — marked "HTML converter only"
`lib/coradoc/core_model/image.rb:34-36`:
```ruby
# @note Populated by HTML converter only
attribute :caption, :string
```

## Fix

Move these to the HTML format gem's model extensions. Either:
- Create `HtmlTableCell` that wraps CoreModel's `TableCell` with HTML-specific attributes, or
- Use the existing `element_attributes` mechanism to carry format-specific key-value pairs.
