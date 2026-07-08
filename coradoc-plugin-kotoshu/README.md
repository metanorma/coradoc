# coradoc-plugin-kotoshu

Spell-check AsciiDoc documents with [Kotoshu 「言修」](https://github.com/kotoshu/kotoshu),
using [Coradoc](https://github.com/lutaml/coradoc)'s format-neutral CoreModel as the
document tree.

The plugin produces a **Word-style spell-check report** (YAML or JSON): a header
with document path, language, generation timestamp, and summary counts, followed
by an entry per misspelled occurrence — the misspelled word, a snippet of
surrounding text, the enclosing section, a best-effort source line, and
Kotoshu's suggestions.

## Why a Coradoc plugin?

Kotoshu is a spell checker — it knows nothing about document structure.
Coradoc knows everything about document structure, but cannot spell check.
This plugin bridges the two: it asks Coradoc for the document tree, walks the
tree to extract prose (paragraphs, list items, table cells, section titles,
note/example/quote blocks, footnotes), and runs each token through Kotoshu.

Source-code, listing, literal, pass, and comment blocks are skipped. Document
header cruft (author lines, attribute lines like `:toc:`) is filtered out.

## Installation

```bash
gem install coradoc-plugin-kotoshu
```

Or in a Gemfile:

```ruby
gem "coradoc-plugin-kotoshu"
```

You'll also need Kotoshu set up for the language you want to check:

```ruby
require "kotoshu"
Kotoshu.setup(:en)   # one-time, downloads dictionary + affixes to ~/.cache/kotoshu
```

## CLI

```bash
coradoc-kotoshu check README.adoc --language en --format yaml
coradoc-kotoshu check README.adoc --language en --format json --output report.json

# Use a custom plain-text dictionary instead of Kotoshu's per-language lookup:
coradoc-kotoshu check README.adoc --spellchecker ./words.txt --format yaml
```

Flags:

| Flag | Default | Description |
| --- | --- | --- |
| `-l, --language CODE` | `en` | BCP-47 code; passed to `Kotoshu.spellchecker_for` |
| `-f, --format yaml\|json` | `yaml` | Report format |
| `-o, --output PATH` | stdout | Write report to a file |
| `-s, --spellchecker PATH` | (none) | Path to a plain-text dictionary; overrides `--language` |
| `--verbose` | off | Print progress to stderr |
| `-v, --version` | | Print plugin version |

Exit code is non-zero on invalid input or an unknown format. Misspellings do
**not** cause a non-zero exit — the report is the contract.

## Library API

```ruby
require "coradoc/plugin/kotoshu"

checker = Coradoc::Plugin::Kotoshu::Checker.new(language: "en")
report  = checker.check_file("README.adoc")

puts report.to_yaml
puts "Found #{report.error_count} misspelling(s) across " \
     "#{report.unique_error_count} unique word(s)."

report.errors.each do |err|
  puts "  #{err.word} (#{err.element}#{err.section ? " in '#{err.section}'" : ''}, line #{err.line || '?'})"
  puts "    suggestions: #{err.suggestions.join(', ')}" if err.has_suggestions?
end
```

You can inject any object that responds to `#check_word` (returning a
`Kotoshu::Models::Result::WordResult`) and `#tokenize` (returning
`[[word, position], ...]`):

```ruby
require "kotoshu"

dict = Kotoshu::Dictionary::PlainText.new("./my-glossary.txt", language_code: "en")
sc   = Kotoshu::Spellchecker.new(dictionary: dict)

checker = Coradoc::Plugin::Kotoshu::Checker.new(spellchecker: sc, language: "en")
report  = checker.check(adoc_text, document: "inline")
```

### Asciidoc parsing

The plugin uses `Coradoc.parse(text, format: :asciidoc)`. The `coradoc-adoc`
gem is a hard runtime dependency so the `:asciidoc` format is always
registered.

## Report schema

```yaml
---
document: README.adoc
language: en
generated_at: '2026-06-27T09:52:29Z'
checker_version: 0.1.0
word_count: 33
error_count: 16
unique_error_count: 13
errors:
- word: paragraf
  context: "...reamble paragraf with a misspelled helo word."
  element: paragraph        # paragraph | list_item | table_cell | footnote | ...
  section: Section One      # enclosing section title, or nil
  line: 5                   # best-effort 1-based source line, or nil
  suggestions:
  - paragraph
```

The `Report` and `ReportError` classes use [lutaml-model](https://github.com/lutaml/lutaml-model)
for serialization, so `#to_yaml`, `#to_json`, `.from_yaml`, and `.from_json`
are all framework-supplied.

## Source line numbers

Coradoc's CoreModel does not currently record source line numbers. The plugin
reconstructs a line by scanning the original AsciiDoc source for the first
non-trivial (length ≥ 4) token of each span's text. This is a best-effort
heuristic and may be off when the same token appears on multiple lines. When
the source is unavailable (e.g., the plugin is given a pre-parsed tree
without source), `line` is `nil`.

## Development

```bash
bundle install
bundle exec rspec                       # full suite
bundle exec rspec spec/plugin/          # only plugin specs
bundle exec rspec -e "paragraph"        # by example name
bundle exec exe/coradoc-kotoshu version
```

The Gemfile points at the sibling `../kotoshu` source tree when present, so
local changes to Kotoshu are picked up immediately.

## License

BSD-2-Clause. See `LICENSE` for details.
