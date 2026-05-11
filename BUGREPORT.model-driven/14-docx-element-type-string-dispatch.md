# 14: DOCX from_core_model still uses element_type string dispatch

## Status: FIXED

- `from_core_model.rb` uses `case element.element_type` with string matching
- Should use class-based `case element; when DocumentElement` pattern


**Severity:** MEDIUM
**Location:** `coradoc-docx/lib/coradoc/docx/transform/from_core_model.rb`

## Evidence

Line 85-92: `case element.element_type` matching `'document'`, `'section'`
Line 130-139: `case block.element_type` matching `'page_break'`, `'paragraph'`, `'comment'`
Line 209-214: `case block.element_type` matching `'page_break'`

The ADOC and Markdown gems already use class-based dispatch. DOCX should follow the same pattern.

## Fix

Replace `case element.element_type` with `case element; when CoreModel::DocumentElement` etc. Replace `case block.element_type` with `case block; when CoreModel::ParagraphBlock` etc.
