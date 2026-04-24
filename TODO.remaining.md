# Remaining Work

All completed TODOs have been deleted. This file tracks future work that is not yet started or requires external dependencies.

---

## 1. DOCX — CoreModel → OOXML Round-Trip (Writing DOCX)

**Status**: DONE.

Implemented `Coradoc::Docx::Transform::FromCoreModel` with full element dispatch using Uniword Builder API:
- `StructuralElement` → heading paragraphs with style references
- `Block` → paragraphs with inline formatting preservation
- `ListBlock` → paragraphs with `numPr` (numbering properties)
- `Table` → OOXML table with rows/cells/colspan/rowspan
- `Image` → text placeholder (full image embedding needs binary packaging)
- `InlineElement` → runs with bold/italic/underline/strikethrough/sub/super properties
- `serialize` registered in `Coradoc::Docx` module, `serialize?` returns `true`

Round-trip specs in `coradoc-docx/spec/integration/round_trip_spec.rb`.

---

## 2. DOCX — OOXML Element Coverage

**Status**: DONE.

All priority items implemented:
- **Tab stops** (`w:tab`) → tab character
- **Simple fields** (`w:fldSimple`) → `SimpleFieldRule` with HYPERLINK/TOC/PAGE filtering
- **Inline math** (`m:oMath` within runs) → dispatched via `run_rule.rb` and `ordered_content.rb`
- **Run rStyle** — already handled (confirmed)
- **Run highlight** — already handled (confirmed)
- **Effective run properties** — already handled (confirmed)
- **Deleted text** (`w:delText`) → strikethrough InlineElement
- **Symbols** (`w:sym`) → character extraction
- **No-break hyphens** (`w:noBreakHyphen`) → U+2011
- **Soft hyphens** (`w:softHyphen`) → U+00AD
- **Carriage return** (`w:cr`) → hard_line_break InlineElement
- **Alternate content** (`mc:AlternateContent`) → fallback extraction
- **Proofing errors** (`w:proofErr`) → `ProofErrorRule` silently strips

---

## 3. DOCX — Real-World Integration Tests

**Status**: PARTIALLY DONE.

### Done
- Markdown inline element support — **already fixed** (uses `renderable_content`, not `block.content.to_s`)
- Round-trip specs for DOCX writing (in-memory mock OOXML objects)
- Mixed-content paragraph tests for Markdown FromCoreModel

### Remaining
- Real DOCX file tests with fixture generator (needs real `.docx` files or Uniword Builder fixture generation)
- Document corpus testing (Metanorma ISO standards, embedded images, equations, tracked changes)
- Image embedding in FromCoreModel (currently text placeholder; needs binary packaging support)

---

## 4. DOCX — Headers, Footers, Sections

**Status**: DONE.

- **Header/footer text extraction** — extracts semantic text, discards layout-only text (page numbers, dates, "Page X of Y")
- **Section breaks** — detected via paragraph `sectPr`, standalone breaks become `thematic_break` blocks
- **Print-layout table trimming** — already done in `TableRule` (frame, grid, width not mapped)
- Image dimensions preserved as-is (semantic)

---

## 5. Normalize Module — Lutaml-Model `to_hash` Migration

**Status**: DONE.

---

## 6. Markdown Parser — Inline Element Support in Setext Headings

**Status**: DONE.
