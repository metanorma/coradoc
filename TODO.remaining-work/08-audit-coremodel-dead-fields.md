# 08 — Audit CoreModel Dead Fields

**Status**: PENDING
**Priority**: P3
**Effort**: Medium

## Problem

CoreModel defines many attributes that no transformer ever populates or reads. These add complexity, confusion, and maintenance burden without providing value.

### Never Populated by Any ToCoreModel

| Type | Dead Field |
|---|---|
| `Table` | `frame`, `grid`, `width`, `float`, `col_alignments`, `col_styles`, `bgcolor` |
| `TableCell` | `bgcolor`, `color`, `width`, `height`, `repeat` |
| `Image` | `caption`, `link`, `float` |
| `ElementAttribute` | `namespace`, `namespace_prefix` |
| `Block` | `delimiter_length` (only Builder sets this) |
| `InlineElement` | `constrained` (only Builder sets this) |
| `ListBlock` | `start` |
| `StructuralElement` | `content` (children is used instead) |

### Never Read by Any FromCoreModel

| Type | Dead Field |
|---|---|
| `Table` | `frame`, `grid`, `width`, `float`, `col_alignments`, `col_styles`, `bgcolor` |
| `TableCell` | `bgcolor`, `color`, `width`, `height`, `repeat`, `style`, `vertical_alignment` |
| `Image` | `caption`, `link`, `float` |
| `Term` | `definition`, `source` |
| `Footnote` | `inline_content` |
| `Block` | `delimiter_length`, `lines` |
| `InlineElement` | `constrained`, `nested_elements` |

## Model-Driven Approach

Each attribute should exist because at least one format transformer needs it. The approach:

1. **Wire up** attributes that have a clear format source and target (e.g., `Table.frame` exists in OOXML and AsciiDoc)
2. **Remove** attributes that have no format source (e.g., `ElementAttribute.namespace_prefix` — no format has namespace-prefixed attributes)
3. **Document** the remaining dead fields with a `@note` in the model class indicating which formats should populate them

This follows the open/closed principle: CoreModel declares what *can* be captured; each format gem decides what it *does* capture.

## Scope

### Wire Up (high-value fields)
- `Table.frame` / `grid` — AsciiDoc tables have `[frame=topbot]`, OOXML has `w:tblBorders`
- `TableCell.colspan` / `rowspan` — already populated by DOCX, should be preserved
- `Image.caption` — AsciiDoc block images have captions
- `ListBlock.start` — ordered lists have start numbers in OOXML

### Evaluate and Remove (dead code)
- `ElementAttribute.namespace` / `namespace_prefix` — no format uses namespaces in attributes
- `TableCell.repeat` — no known format equivalent
- `Table.bgcolor` / `TableCell.bgcolor` — CSS handles this in HTML, not CoreModel's concern

### Document
- Add `@note` annotations to fields that are populated by only some formats

## Acceptance Criteria

- [ ] High-value fields are wired up in at least one ToCoreModel and one FromCoreModel
- [ ] Truly dead fields are removed with a clear commit message
- [ ] Remaining partially-used fields have `@note` documentation
- [ ] All specs pass
