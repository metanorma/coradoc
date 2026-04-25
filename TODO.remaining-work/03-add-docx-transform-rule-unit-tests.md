# 03 — Add DOCX Transform Rule Unit Tests

**Status**: PENDING
**Priority**: P1
**Effort**: Medium

## Problem

The DOCX gem has the worst lib-to-spec ratio in the project (8.7:1). All 15 transform rule files under `coradoc-docx/lib/coradoc/docx/transform/rules/` have **zero** dedicated unit tests:

- `bookmark_rule.rb`, `break_rule.rb`, `footnote_rule.rb`, `heading_rule.rb`
- `hyperlink_rule.rb`, `image_rule.rb`, `list_item_rule.rb`, `math_rule.rb`
- `paragraph_rule.rb`, `proof_error_rule.rb`, `run_rule.rb`, `simple_field_rule.rb`
- `structured_document_tag_rule.rb`, `table_rule.rb`, `text_rule.rb`

Additionally, these infrastructure classes have no specs:
- `context.rb`, `numbering_resolver.rb`, `ordered_content.rb`
- `rule.rb`, `rule_registry.rb`, `style_resolver.rb`

Rules are only tested indirectly through `to_core_model_spec.rb` and `round_trip_spec.rb`. Rule-level regressions are invisible.

## Model-Driven Approach

Each rule encapsulates a single OOXML → CoreModel transformation. Tests should exercise each rule in isolation by constructing minimal OOXML objects (using the builder helpers from `spec_helper.rb`) and asserting the CoreModel output. This respects encapsulation — rules are tested through their public `matches?` / `apply` interface without coupling to internal details.

## Scope

- Create `coradoc-docx/spec/coradoc/docx/transform/rules/` directory
- Write one spec file per rule, testing `matches?` and `apply` for the primary and edge cases
- Create specs for infrastructure classes (`context`, `style_resolver`, `rule_registry`, `numbering_resolver`)

## Priority Order

1. `run_rule_spec.rb` — most complex rule, handles inline formatting extraction
2. `heading_rule_spec.rb` — critical for document structure
3. `table_rule_spec.rb` — complex nested structure
4. `paragraph_rule_spec.rb` — most common element type
5. `list_item_rule_spec.rb` — grouping logic
6. Remaining rules

## Acceptance Criteria

- [ ] Each rule has a dedicated spec file with `matches?` and `apply` tests
- [ ] Style resolver and numbering resolver have specs
- [ ] Rule registry spec covers registration, lookup, and priority ordering
- [ ] All specs pass
