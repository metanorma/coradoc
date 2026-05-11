# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Coradoc is a Ruby hub-and-spoke document transformation library. A canonical `CoreModel` serves as the central hub, and format-specific gems (AsciiDoc, HTML, Markdown) are spokes. Adding a new format requires only two transformers (ToCoreModel, FromCoreModel).

## Monorepo Structure

- **`coradoc/`** — Core gem: `CoreModel`, `Registry`, `Transform::Base`, hooks, validation, streaming, query API
- **`coradoc-adoc/`** — AsciiDoc gem: Parslet-based parser, document model, serializer, transformer (ToCoreModel/FromCoreModel)
- **`coradoc-html/`** — HTML gem: Nokogiri-based converter, classic renderer, Vue.js SPA theme
- **`coradoc-markdown/`** — Markdown gem: Parslet-based CommonMark parser, document model, serializer
- **`coradoc-docx/`** — DOCX gem: Uniword-based OOXML transformer

Each gem has its own gemspec, `lib/`, `spec/`, and `Rakefile`. All are loaded together via the root `Gemfile` using `path:` references. Run `rake spec` inside any gem directory for standalone specs.

## Build & Test Commands

```bash
bundle install              # Install dependencies (all gems together)

# Tests (from monorepo root)
bundle exec rake spec_all                  # Run ALL gem specs (main + sub-gems)
bundle exec rake spec:coradoc              # Run only coradoc specs
bundle exec rake spec:coradoc_adoc         # Run only coradoc-adoc specs
bundle exec rake spec:coradoc_html         # Run only coradoc-html specs
bundle exec rake spec:coradoc_markdown     # Run only coradoc-markdown specs
bundle exec rake spec:coradoc_docx         # Run only coradoc-docx specs

# Tests (from inside a gem directory)
cd coradoc && bundle exec rake spec        # Run coradoc specs standalone
cd coradoc-adoc && bundle exec rake spec   # Run adoc specs standalone

# Linting
bundle exec rubocop

# Console
bundle exec rake console     # IRB with coradoc preloaded
```

## Architecture

### CoreModel (`coradoc/lib/coradoc/core_model.rb`)

The canonical document representation using `lutaml-model`. Key types: `StructuralElement`, `Block`, `ListBlock`, `ListItem`, `InlineElement`, `Table`, `Image`, `Metadata`, `Footnote`, `DefinitionList`, `Bibliography`. All inherit from `CoreModel::Base`.

### Transformation Flow

```
Source text → Format::Parser → Format Model → ToCoreModel → CoreModel → FromCoreModel → Target Model → Serialize → Target text
```

- `Coradoc.convert(text, from: :asciidoc, to: :html)` — end-to-end conversion
- `Coradoc.parse(text, format:)` — parse to CoreModel
- `Coradoc.serialize(core, to:)` — serialize CoreModel to output

### Format Registration

Format gems register via `Coradoc.register_format(:name, Module)` and must implement `parse_to_core`/`parse` and `serialize`. The `Registry` class in `coradoc/lib/coradoc/registry.rb` manages this.

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

- **NO VERSION RELEASES**: Do not trigger gem releases or version bumps via GHA or any other mechanism. This restriction applies until the user explicitly says otherwise.
- **NO HASHES IN MODELS**: CoreModel classes must NEVER use `:hash` as an attribute type. Every attribute must be a typed model, string, integer, or array of typed models. No hash bags, no generic key-value stores. This enforces the model-driven architecture.
- **NO SERIALIZATION IN MODELS**: CoreModel classes must NEVER contain `to_hash`, `to_json`, `serialize`, or any custom serialization methods. Models are pure data structures. Serialization is handled by dedicated serializer classes (lutaml-model handles this automatically).
- **NO RAW HTML STRINGS**: The HTML gem must use Nokogiri as both the model layer AND the HTML builder. Never concatenate raw HTML strings. Never manually construct HTML in text. Use `Nokogiri::HTML::Builder` or `Nokogiri::XML::Node` methods to construct HTML output. ALL non-model-driven HTML construction code must be converted to Nokogiri builder.
- **Model classes own only their native format**: No `to_adoc` in Markdown models, no `to_md` in AsciiDoc models. Cross-format conversion always routes through CoreModel transformers (ToCoreModel / FromCoreModel). This enforces SRP, OCP, and DIP.
- **Autoload over require_relative**: Use `autoload` with `#{__dir__}` paths (see `core_model.rb` for pattern). Exception: files with load-time side effects (registrations, `apply` calls) use `require_relative`.
- **Error-raising in serializers**: Unknown types in `serialize_content` should raise `ArgumentError`, never fall back to `to_s`. This catches missing serializers immediately rather than producing Ruby object dumps.
- **Ruby 3.3+ target**, `TargetRubyVersion: 3.3` in RuboCop.
- RSpec uses `--format documentation`, `--color`, `expect` syntax, `disable_monkey_patching!`.
- Benchmark tests are excluded unless `BENCHMARK=true`.
