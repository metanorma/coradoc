# 09: AsciiDoc parser stores definition list terms and definitions as raw strings

## Status: PARTIALLY FIXED

- `dlist_term` parser updated to parse `[[anchor]]` syntax and extract IDs
- Transformer handles `TextElement` case for ID extraction from terms
- `dlist_definition` still uses raw text for definition content (workaround via transformer re-parsing)
- Full inline markup parsing in definition content not yet implemented


**Severity:** HIGH
**Location:** `coradoc-adoc/lib/coradoc/asciidoc/parser/list.rb`, `coradoc-adoc/lib/coradoc/asciidoc/transformer/list_rules.rb`

## Test file

`/Users/mulgogi/src/chinese/cham-format/sections/03-terms.adoc` — contains a definition list with `[[term-cham-file]]CHAM file:: ...See <<file-format>>.` entries, and backtick monospace in descriptions.

## Problem

The AsciiDoc parser captures definition list terms and definitions as raw strings without processing inline markup. The `[[anchor]]` syntax, `<<cross-reference>>` syntax, and backtick monospace inside definition list items are never parsed into inline model objects. They pass through as literal text.

## Evidence

### 9A. Parser captures term as raw characters

`coradoc-adoc/lib/coradoc/asciidoc/parser/list.rb:109-111`:
```ruby
def dlist_term(_delimiter)
  match("[^\n:]").repeat(1)
                 .as(:dlist_term) >> dlist_delimiter
end
```

This captures everything before `::` as an opaque string. The `[[term-cham-file]]` anchor prefix and any inline formatting in the term text are captured as raw characters.

### 9B. Parser captures definition as raw text

`coradoc-adoc/lib/coradoc/asciidoc/parser/list.rb:114-117`:
```ruby
def dlist_definition
  text # >> empty_line.repeat(0)
    .as(:definition) >> line_ending >> empty_line.repeat(0)
end
```

The `text` parser atom does not invoke the `inline` sub-parser, so backticks, `<<xref>>`, and other inline markup in the definition are never recognized.

### 9C. Transformer converts to raw string

`coradoc-adoc/lib/coradoc/asciidoc/transformer/list_rules.rb:65-67`:
```ruby
rule(dlist_term: simple(:term), delimiter: simple(:_delim)) do
  term.to_s
end
```

The transformer rule calls `.to_s` on the term, producing a plain string. No `Model::Term` object is created with structured content.

### 9D. Transformer stores definition as string

`coradoc-adoc/lib/coradoc/asciidoc/transformer/list_rules.rb:100-104`:
```ruby
contents = definition.to_s
Model::List::DefinitionItem.new(terms: terms, contents: contents)
```

`definition.to_s` collapses everything to a flat string.

### 9E. Confirmed parser output

Running the parser on `[[term-cham-file]]CHAM file:: A thing. See <<file-format>>.` produces:
```
Item 0: DefinitionItem
  id: nil
  terms: ["[[term-cham-file]]CHAM file"]
  contents: "A thing. See <<file-format>>."
```

Both the `[[anchor]]` prefix and `<<xref>>` are raw strings. No `Model::Inline::CrossReference` or anchor model exists.

### 9F. Same issue in Admonition model

`coradoc-adoc/lib/coradoc/asciidoc/model/admonition.rb:31`:
```ruby
attribute :content, :string
```

Admonition content is stored as `:string`, so even if the parser recognized inline markup in NOTE content, the model can't hold it.

## Impact

Any consumer that needs to render cross-references as links, anchors as `id` attributes, or backtick text as monospace gets literal strings instead of structured inline elements. The HTML gem currently works around this by pattern-matching on the rendered HTML text (see Bug 07 for the broader architectural issue).

## Fix

1. **Parser**: In `dlist_term`, invoke `element_id_inline` before the term text to capture `[[anchor]]` syntax. In `dlist_definition`, invoke the `inline` sub-parser to recognize backticks, cross-references, and other inline markup.

2. **Transformer**: Convert the parsed AST into structured model objects. Terms should produce `Model::Term` instances with structured content (not plain strings). Definitions should produce `Model::TextElement` instances with inline content arrays.

3. **Admonition model**: Change `attribute :content, :string` to support structured content with inline elements, matching the pattern used by `Model::TextElement`.

4. **CoreModel**: See report 10 for DefinitionItem model changes needed to receive this structured content.
