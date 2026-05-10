# 11: CoreModel StructuralElement headings have no auto-generated IDs

## Status: FIXED

- `IdGenerator` module added to `CoreModel` with format-neutral ID generation from title text
- `ToCoreModel` transformer generates IDs from title when no explicit `[[anchor]]` is present
- Explicit anchors take precedence over auto-generated IDs
- Redundant `add_heading_ids` Nokogiri post-processing removed from `ClassicRenderer`


**Severity:** MEDIUM
**Location:** `lib/coradoc/core_model/structural_element.rb`, `coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb`

## Test file

`/Users/mulgogi/src/chinese/cham-format/cham-spec.adoc` — 137 headings, most without explicit `[[anchor]]` syntax. Build output at `/Users/mulgogi/src/chinese/cham-format/dist/index.html`.

## Problem

The AsciiDoc spec declares `:sectanchors:` which should auto-generate `id` attributes on every section heading. But in the pipeline:

1. The AsciiDoc parser only creates an `id` on a section when it sees explicit `[[anchor]]` syntax before the heading.
2. The ToCoreModel transformer passes through whatever `id` the parser set (or didn't set).
3. The CoreModel `StructuralElement` has an `id` attribute but no logic to generate one from the title.

The result: headings without explicit anchors have no `id` attribute. The TOC builder in the HTML renderer generates link targets from heading text, but those targets don't exist in the page — the links are broken.

## Evidence

### 11A. Parser only captures explicit anchors

`coradoc-adoc/lib/coradoc/asciidoc/parser/content.rb:49-54`:
```ruby
def element_id
  line_start? >>
    ((str('[[') >> keyword.as(:id) >> str(']]')) |
       (str('[#') >> keyword.as(:id) >> str(']'))
    ) >> newline
end
```

Only `[[id]]` or `[#id]` produce an `id`. No fallback generation from heading text.

### 11B. ToCoreModel passes through parser's id (or nil)

`coradoc-adoc/lib/coradoc/asciidoc/transform/to_core_model.rb:125-135` (the `transform_section` method):
```ruby
def transform_section(section)
  title = extract_title_text(section.title)
  # ...
  element = Coradoc::CoreModel::StructuralElement.new(
    element_type: 'section',
    level: level,
    title: title,
    # ...
  )
  element.id = section.id if section.id
  element
end
```

When `section.id` is `nil` (no explicit `[[anchor]]`), the CoreModel element gets no `id`.

### 11C. HTML Section converter only sets id when model.id exists

`coradoc-html/lib/coradoc/html/converters/section.rb:58-59`:
```ruby
title_attrs = {}
title_attrs[:id] = model.id if model.id
```

Headings without explicit anchors render as `<h3>` with no `id` attribute.

### 11D. TOC builder generates IDs that don't exist

`coradoc-html/lib/coradoc/html/theme/classic_renderer.rb:294-300`:
```ruby
def extract_section_id(section)
  if section.id
    section.id
  else
    title = extract_section_title(section)
    "_#{title.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_+|_+$/, '')}"
  end
end
```

The TOC generates link targets like `#_design_principles` for headings that have no `id` in the page. The links point to nothing.

### 11E. Confirmed output: 137 headings, most without IDs

Building the CHAM spec produces:
- 17 h2 headings — all with explicit `id` (e.g., `id="introduction"`)
- 72 h3 headings — most WITHOUT `id` until a post-processing workaround adds them
- 48 h4 headings — most WITHOUT `id` until post-processing

### 11F. Current workaround

The ClassicRenderer runs `add_heading_ids` (Nokogiri post-processing) before section numbering to inject auto-generated IDs. This works but is a renderer-side patch over a CoreModel gap. If another format gem (DOCX, PDF) also needs heading IDs for cross-references, it must reimplement the same logic.

## Impact

Cross-references from TOC and `<<xref>>` links fail when targeting headings without explicit anchors. Every format gem must independently implement ID generation.

## Fix

1. **ToCoreModel transformer**: After constructing a `StructuralElement` for a section, if `section.id` is nil, generate an `id` from the title text. The generation logic should live in one place (the transformer), not in each format gem's renderer.

   Example:
   ```ruby
   element.id = section.id || generate_id_from_title(title)
   ```

2. **Move ID generation to CoreModel or shared utility**: The `generate_id_from_title` method should be format-neutral: lowercase, strip non-alphanumeric characters, replace spaces with underscores, prefix with `_`. This is the same convention AsciiDoc uses and is applicable to HTML, PDF, and DOCX.

3. **Remove the Nokogiri post-processing workaround**: Once the CoreModel carries auto-generated IDs, the `add_heading_ids` method in the ClassicRenderer becomes unnecessary and can be removed.

4. **Respect explicit anchors**: Explicit `[[anchor]]` values take precedence over auto-generated IDs. The current `element.id = section.id if section.id` pattern already handles this — the fix is adding the else branch.
