# 06 — Expand DOCX FromCoreModel CoreModel Type Coverage

**Status**: PENDING
**Priority**: P2
**Effort**: Medium

## Problem

The DOCX `FromCoreModel` (410 lines) handles only a subset of CoreModel types. These types are silently dropped:

| CoreModel Type | Current Status |
|---|---|
| `Footnote` | Dropped — DOCX supports footnotes via `w:footnoteReference` |
| `FootnoteReference` | Dropped — should produce `w:footnoteReference` inline |
| `DefinitionList` | Dropped — should render as a table or styled list |
| `DefinitionItem` | Dropped — part of definition list rendering |
| `Term` | Dropped — should render with special style |
| `Toc` | Dropped — DOCX has `w:sdt` for TOC fields |
| `Bibliography` | Dropped — should render as a styled section |
| `BibliographyEntry` | Dropped — part of bibliography rendering |
| InlineElement `highlight` | Dropped — should produce highlighted run |
| InlineElement `xref` | Dropped — should produce `w:hyperlink` with anchor |
| InlineElement `stem` | Dropped — should produce `m:oMath` (if Uniword supports it) |

## Model-Driven Approach

Each CoreModel type maps to one or more OOXML constructs. The FromCoreModel dispatch should produce proper OOXML objects via the Uniword Builder API, following the same open/closed pattern as the AsciiDoc `FromCoreModelRegistrations`:

- New CoreModel types should be handled by adding dispatch cases, not modifying existing ones
- Each OOXML construction should be a private method with clear input/output contracts
- The `transform` method should be a clean case statement dispatch that delegates to private methods

### Priority Mapping

1. **Footnote / FootnoteReference**: High — common in real documents, OOXML has native support
2. **DefinitionList**: Medium — maps naturally to a two-column table with styling
3. **InlineElement highlight/xref**: Medium — OOXML has `w:highlight` and `w:hyperlink`
4. **Term**: Low — needs custom style definition
5. **Toc / Bibliography**: Low — complex OOXML structures (`w:sdt`, bibliography fields)

## Scope

- Add dispatch cases in `from_core_model.rb` for each missing CoreModel type
- Add OOXML construction methods (private) for footnote references, definition lists, etc.
- Refactor the 410-line file into separate handler modules or extract builder methods
- Add specs for each new dispatch case

## Acceptance Criteria

- [ ] `Footnote` and `FootnoteReference` produce OOXML footnote structures
- [ ] `DefinitionList` produces a two-column OOXML table
- [ ] InlineElement `highlight` produces `w:highlight` run
- [ ] InlineElement `xref` produces `w:hyperlink` with anchor
- [ ] All other missing types have at least a fallback (not silently dropped)
- [ ] FromCoreModel is under 300 lines (extract helpers or modules)
- [ ] All existing specs pass
