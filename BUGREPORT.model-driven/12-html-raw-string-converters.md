# 12: 23 HTML converter files use raw string concatenation instead of NodeBuilder

## Status: FIXED

- 23 converter files in `coradoc-html/lib/coradoc/html/converters/` construct HTML via string interpolation
- 26 files already use NodeBuilder correctly (bold, paragraph, section, table, etc.)
- The clean pattern exists and is well-established — conversion is mechanical


**Severity:** HIGH
**Location:** `coradoc-html/lib/coradoc/html/converters/` (23 files)

## Problem

The `NO RAW HTML STRINGS` convention in CLAUDE.md mandates that all HTML construction must use NodeBuilder or Nokogiri. However, 23 converter files still construct HTML via string interpolation (`%()`, `"#{}"`, heredocs).

26 converters already follow the pattern correctly. The clean pattern is well-established — conversion is mechanical.

## Affected Files (RAW)

| File | Key Raw Patterns |
|------|-----------------|
| `admonition.rb` | `%(<div#{attrs}>\n...#{content}...</div>)`, `"<p>#{...}</p>"` |
| `attribute.rb` | `"<!-- :#{key}: -->"` |
| `audio.rb` | heredocs for `<figure>/<audio>`, `%(<source src=...>)` |
| `bibliography.rb` | `%(<section#{attrs}>...#{content}...</section>)` |
| `bibliography_entry.rb` | `%(<a id=...>)`, `%(<div#{attrs}>...</div>)` |
| `comment_block.rb` | `"<!--\n#{content}\n-->"` |
| `comment_line.rb` | `"<!-- #{content} -->"` |
| `cross_reference.rb` | `%(<a href=...>#{text}</a>)` |
| `example.rb` | `%(<div#{attrs}>...#{content}...</div>)`, `"<p>#{...}</p>"` |
| `include.rb` | `"<!-- #{content} -->"` |
| `listing.rb` | `%(<pre#{attrs}>#{content}</pre>)` |
| `literal.rb` | `%(<pre#{attrs}>#{content}</pre>)` |
| `open.rb` | `"<div#{attrs}>...#{content}...</div>"` |
| `quote.rb` | `"<blockquote#{attrs}>...#{content}...</blockquote>"` |
| `reviewer_comment.rb` | multiline `%(<div#{attrs}>...)` |
| `reviewer_note.rb` | multiline `%(<aside#{attrs}>...)` |
| `sidebar.rb` | `%(<aside#{attrs}>...#{content}...</aside>)` |
| `source.rb` | `%(<pre...><code...>#{content}</code></pre>)` |
| `table_cell.rb` | `"<#{tag}#{attrs}>#{content}</#{tag}>"` |
| `table_row.rb` | `"<tr#{attrs}>...#{content}...</tr>"` |
| `term.rb` | `%(<span class=...>#{text}</span>)` |
| `verse.rb` | `%(<pre class="verse">#{content}</pre>)` |
| `video.rb` | heredocs for `<figure>/<video>`, `%(<source src=...>)` |

Also in theme layer:
- `classic_renderer.rb` (build_html5_document — array join of raw HTML strings)
- `config.rb` (css_tags, js_tags — raw `<link>`, `<script>` strings)
- `theme/base.rb` (build_meta_tags — raw `<meta>` strings)
- `modern_renderer.rb` (build_meta_tags — raw `<meta>` strings)

## Clean Pattern (from bold.rb, paragraph.rb, etc.)

```ruby
def self.to_html(model, options = {})
  content = escape_html(model.content)
  attrs = {}
  attrs[:id] = model.id if model.id
  build_element('strong', content, **attrs)
end
```

Where `build_element` delegates to `NodeBuilder.build(tag, content, **attrs)`.

## Fix

Convert each RAW file to use `NodeBuilder.build(tag, content, **attrs)` following the established pattern. The `build_element` helper in `base.rb` already provides the correct interface.
