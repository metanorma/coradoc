# 10 — Update CLAUDE.md Stale References

**Status**: PENDING
**Priority**: P3
**Effort**: Small

## Problem

CLAUDE.md references three active work items in `TODO.new-continue/`:

```
1. `01-remove-cross-format-coupling.md` — Remove `to_adoc`/`to_html_attrs` from Markdown models
2. `02-complete-autoload-migration.md` — Finish autoload migration in coradoc-adoc (phases 6-9)
3. `03-verify-serialization-fixes.md` — Verify no Ruby dumps, audit inline FIXMEs
```

The `TODO.new-continue/` directory **does not exist**. These files were deleted when the work was completed. The CLAUDE.md section is stale and misleading.

## Status Assessment

| Item | Actual Status |
|---|---|
| `01-remove-cross-format-coupling` | **DONE** — zero cross-format methods found in any gem |
| `02-complete-autoload-migration` | **PARTIALLY DONE** — ADoc gem is migrated; core gem still has ~20 `require_relative` |
| `03-verify-serialization-fixes` | **PARTIALLY DONE** — ADoc serializers raise ArgumentError; Markdown still falls back to `to_s` |

## Scope

- Remove the `## Active Work (TODO.new-continue/)` section from CLAUDE.md
- Add a `## Remaining Work (TODO.remaining-work/)` section pointing to the new TODO files
- Update the `TODO.remaining-work` references to match the new structure
- Keep the `TODO.uniword/` reference if that directory still exists and is relevant

## Acceptance Criteria

- [ ] CLAUDE.md no longer references `TODO.new-continue/`
- [ ] Active work items replaced with pointer to `TODO.remaining-work/`
- [ ] No broken references in CLAUDE.md
