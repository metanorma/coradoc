# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Coradoc is a Ruby hub-and-spoke document transformation library. A canonical `CoreModel` serves as the central hub, and format-specific gems (AsciiDoc, HTML, Markdown) are spokes. Adding a new format requires only two transformers (ToCoreModel, FromCoreModel).

## Monorepo Structure

- **`lib/coradoc/`** — Core gem: `CoreModel`, `Registry`, `Transform::Base`, hooks, validation, streaming, query API
- **`coradoc-adoc/`** — AsciiDoc gem: Parslet-based parser, document model, serializer, transformer (ToCoreModel/FromCoreModel)
- **`coradoc-html/`** — HTML gem: Nokogiri-based converter, classic renderer, Vue.js SPA theme
- **`coradoc-markdown/`** — Markdown gem: Parslet-based CommonMark parser, document model, serializer

Each sub-gem has its own gemspec, `lib/`, and `spec/` directory. All are loaded together via the root `Gemfile` using `path:` references.

## Build & Test Commands

```bash
bundle install              # Install dependencies (all gems together)

# Tests
bundle exec rspec                          # Run main gem tests
bundle exec rspec spec/coradoc/            # Run specific directory
bundle exec rspec spec/coradoc/query_spec.rb  # Run single test file
bundle exec rspec spec/coradoc/query_spec.rb:42  # Run single test (by line)
bundle exec rake spec_all                  # Run ALL gem specs (main + sub-gems)
bundle exec rake spec:coradoc_adoc         # Run only coradoc-adoc specs
bundle exec rake spec:coradoc_html         # Run only coradoc-html specs
bundle exec rake spec:coradoc_markdown     # Run only coradoc-markdown specs

# Linting
bundle exec rubocop

# Console
bundle exec rake console     # IRB with coradoc preloaded
```

## Architecture

### CoreModel (`lib/coradoc/core_model.rb`)

The canonical document representation using `lutaml-model`. Key types: `StructuralElement`, `Block`, `ListBlock`, `ListItem`, `InlineElement`, `Table`, `Image`, `Metadata`, `Footnote`, `DefinitionList`, `Bibliography`. All inherit from `CoreModel::Base`.

### Transformation Flow

```
Source text → Format::Parser → Format Model → ToCoreModel → CoreModel → FromCoreModel → Target Model → Serialize → Target text
```

- `Coradoc.convert(text, from: :asciidoc, to: :html)` — end-to-end conversion
- `Coradoc.parse(text, format:)` — parse to CoreModel
- `Coradoc.serialize(core, to:)` — serialize CoreModel to output

### Format Registration

Format gems register via `Coradoc.register_format(:name, Module)` and must implement `parse_to_core`/`parse` and `serialize`. The `Registry` class in `lib/coradoc/registry.rb` manages this.

### AsciiDoc Gem Internals

- **Parser** (`coradoc-adoc/lib/coradoc/asciidoc/parser/`) — Parslet-based, rule files: `header`, `inline`, `block`, `list`, `section`, `table`, `bibliography`, `citation`, `stem`, `admonition`
- **Model** (`coradoc-adoc/lib/coradoc/asciidoc/model/`) — ~40+ model classes inheriting from `Model::Base`, built with `lutaml-model`
- **Serializer** (`coradoc-adoc/lib/coradoc/asciidoc/serializer/`) — Converts AsciiDoc models back to `.adoc` strings via element-specific serializer classes
- **Transformer** (`coradoc-adoc/lib/coradoc/asciidoc/transformer.rb`) — Parslet `Transform` subclass with rule modules (HeaderRules, InlineRules, etc.)
- **Transform** (`coradoc-adoc/lib/coradoc/asciidoc/transform/`) — `ToCoreModel` and `FromCoreModel` with registration-based dispatch

### Key Dependencies

- `lutaml-model` — serialization framework for model classes (used by CoreModel and AsciiDoc model)
- `parslet` — PEG parser (used by AsciiDoc and Markdown parsers)
- `nokogiri` — HTML parsing (used by HTML gem)
- `thor` — CLI framework

## Conventions

- **Model classes own only their native format**: No `to_adoc` in Markdown models, no `to_md` in AsciiDoc models. Cross-format conversion always routes through CoreModel transformers (ToCoreModel / FromCoreModel). This enforces SRP, OCP, and DIP.
- **Autoload over require_relative**: Use `autoload` with `#{__dir__}` paths (see `core_model.rb` for pattern). Exception: files with load-time side effects (registrations, `apply` calls) use `require_relative`.
- **Error-raising in serializers**: Unknown types in `serialize_content` should raise `ArgumentError`, never fall back to `to_s`. This catches missing serializers immediately rather than producing Ruby object dumps.
- **Ruby 3.1+ target**, `TargetRubyVersion: 3.1` in RuboCop.
- RSpec uses `--format documentation`, `--color`, `expect` syntax, `disable_monkey_patching!`.
- Benchmark tests are excluded unless `BENCHMARK=true`.

## Active Work (TODO.new-continue/)

1. `01-remove-cross-format-coupling.md` — Remove `to_adoc`/`to_html_attrs` from Markdown models, route through CoreModel
2. `02-complete-autoload-migration.md` — Finish autoload migration in coradoc-adoc (phases 6-9)
3. `03-verify-serialization-fixes.md` — Verify no Ruby dumps, audit inline FIXMEs

## Remaining Work (TODO.uniword/)

Uniword → Coradoc integration: replace word-to-markdown with a model-driven
DOCX → CoreModel → AsciiDoc/Markdown pipeline.

- `04-round-trip-and-from-core-model.md` — (Future) CoreModel → OOXML round-trip
- `06-complete-ooxml-element-coverage.md` — Tab stops, fields, inline math, rStyle, highlight, effective properties
- `08-real-world-integration-tests.md` — Real DOCX file tests, Markdown inline element support
- `09-headers-footers-sections.md` — Headers, footers, section properties extraction
