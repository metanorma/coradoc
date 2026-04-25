# 07 — Wire Bibliography Transformer in AsciiDoc

**Status**: PENDING
**Priority**: P2
**Effort**: Medium

## Problem

`CoreModel::Bibliography` and `CoreModel::BibliographyEntry` exist in CoreModel. The AsciiDoc model has corresponding `Model::Bibliography` and `Model::BibliographyEntry` types. But **no transformer on either side produces or consumes them**. This is fully dead code.

Bibliography is critical for Metanorma/ISO standards documents — a primary use case for Coradoc.

## Model-Driven Approach

The transformer follows the same Registry pattern as other types:

### ToCoreModel
- Register `Coradoc::AsciiDoc::Model::Bibliography` → `transform_bibliography`
- Register `Coradoc::AsciiDoc::Model::BibliographyEntry` → `transform_bibliography_entry`
- `transform_bibliography`: produces `CoreModel::Bibliography` with `id`, `title`, `level`, `entries`
- `transform_bibliography_entry`: produces `CoreModel::BibliographyEntry` with `anchor_name`, `document_id`, `ref_text`, `url`

### FromCoreModel
- Register `CoreModel::Bibliography` → `transform_bibliography`
- Register `CoreModel::BibliographyEntry` → `transform_bibliography_entry`
- Produce AsciiDoc model objects that serialize to `[bibliography]` sections

### Registration
- Add registrations in `to_core_model_registrations.rb` and `from_core_model_registrations.rb`
- The Bibliography type should be dispatched from within the section/document transformer (bibliography sections are typically `StructuralElement` children)

## Scope

- Implement `transform_bibliography` and `transform_bibliography_entry` in both directions
- Register transformers in both `ToCoreModelRegistrations` and `FromCoreModelRegistrations`
- Add specs for both directions
- Test round-trip: ADoc bibliography → CoreModel → ADoc bibliography
- Update the `StructuralElement` handler to recognize bibliography sections by `[bibliography]` attribute

## Acceptance Criteria

- [ ] ADoc `ToCoreModel` produces `CoreModel::Bibliography` from ADoc bibliography sections
- [ ] ADoc `FromCoreModel` produces ADoc bibliography model from `CoreModel::Bibliography`
- [ ] Bibliography entries preserve `anchor_name`, `document_id`, `ref_text`
- [ ] Round-trip spec: ADoc → CoreModel → ADoc preserves bibliography structure
- [ ] All existing specs pass
