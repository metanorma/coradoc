# 09 — Migrate Core Gem require_relative to Autoload

**Status**: PENDING
**Priority**: P3
**Effort**: Medium

## Problem

CLAUDE.md mandates: *"Use `autoload` with `#{__dir__}` paths."* The core gem's `lib/coradoc/coradoc.rb` loads 20+ files eagerly via `require_relative` (lines 233-252). Most are pure utility modules with no load-time side effects:

```ruby
require_relative 'query'
require_relative 'validation'
require_relative 'streaming'
require_relative 'memory'
require_relative 'lazy'
require_relative 'configurable'
require_relative 'transformation_cache'
require_relative 'normalize'
```

These should use `autoload` for faster startup and consistent patterns with the rest of the codebase.

### Exceptions (must remain require_relative)

Files with load-time side effects should stay as `require_relative`:
- `core_model` — triggers lutaml-model type registrations
- `registry` — sets up format registry
- `transform` — registers base transformer
- `input` — registers input processors
- `output` — registers output processors

## Model-Driven Approach

Autoload follows the same pattern used by `CoreModel` and `AsciiDoc::Model`:
```ruby
module Coradoc
  autoload :Query, "#{__dir__}/coradoc/query"
  autoload :Validation, "#{__dir__}/coradoc/validation"
  # ...
end
```

This defers loading until first access, improving startup time for `require 'coradoc'`.

## Scope

- Convert pure utility modules to `autoload` in `coradoc.rb`
- Keep `require_relative` for files with side effects
- Verify no circular dependency issues after migration
- Run full spec suite

## Files to Migrate

- `query` → `autoload :Query`
- `validation` → `autoload :Validation`
- `streaming` → `autoload :Streaming`
- `memory` → `autoload :Memory`
- `lazy` → `autoload :Lazy`
- `configurable` → `autoload :Configurable`
- `transformation_cache` → `autoload :TransformationCache`
- `normalize` → `autoload :Normalize`
- `hooks` → `autoload :Hooks`
- `plugin_discovery` → `autoload :PluginDiscovery`
- `extensions` → `autoload :Extensions`
- `performance_regression` → `autoload :PerformanceRegression`
- `logger` → `autoload :Logger`
- `version` → `autoload :Version`

## Acceptance Criteria

- [ ] All pure utility modules use `autoload`
- [ ] Side-effect files remain as `require_relative`
- [ ] `require 'coradoc'` still loads correctly
- [ ] All specs pass with no load-order issues
