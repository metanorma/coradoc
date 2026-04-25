# 04 — Add Cross-Format End-to-End Integration Tests

**Status**: PENDING
**Priority**: P1
**Effort**: Medium

## Problem

The conversion matrix through `Coradoc.convert(text, from: :X, to: :Y)` has **6 untested format pairs**:

| FROM \ TO | AsciiDoc | HTML | Markdown | DOCX |
|---|---|---|---|---|
| **AsciiDoc** | tested | tested | tested | **UNTESTED** |
| **HTML** | tested | **UNTESTED** | **UNTESTED** | **UNTESTED** |
| **Markdown** | partial | tested | tested | **UNTESTED** |
| **DOCX** | tested (gem) | **UNTESTED** | **UNTESTED** | tested (gem) |

Additionally, `cross_format_spec.rb` does not include DOCX at all. DOCX tests only exist within the `coradoc-docx` gem's own specs.

## Model-Driven Approach

All conversions route through CoreModel. Tests should verify:
1. The CoreModel produced by the source format captures the expected semantics
2. The target format serialization preserves those semantics
3. Round-trip fidelity: source → CoreModel → target → CoreModel → source preserves structure

This tests the model-driven pipeline end-to-end without coupling to format-specific internals.

## Scope

Add to `spec/integration/cross_format_spec.rb`:

1. **DOCX → Markdown**: Construct a DOCX via builder, parse to CoreModel, serialize to Markdown, verify structure
2. **DOCX → HTML**: Same flow, target HTML, verify tags
3. **Markdown → DOCX**: Parse Markdown, serialize to DOCX, verify round-trip
4. **AsciiDoc → DOCX**: Parse ADoc, serialize to DOCX, verify round-trip
5. **HTML → Markdown**: Parse HTML, serialize to Markdown, verify structure
6. **HTML → DOCX**: Parse HTML, serialize to DOCX, verify round-trip

For DOCX tests, use the builder helpers from `coradoc-docx/spec/spec_helper.rb` to construct test documents. For text formats, use inline fixtures.

## Acceptance Criteria

- [ ] All 6 missing format pairs have at least one integration test
- [ ] Tests verify document structure (headings, paragraphs, lists, tables, inline formatting)
- [ ] `cross_format_spec.rb` includes DOCX in the format registry assertions
- [ ] All existing specs pass
