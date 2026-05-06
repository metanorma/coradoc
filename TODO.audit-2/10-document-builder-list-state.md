# TODO 10: DocumentBuilder fragile list state

Status: DONE

## Problem
`@list_items` and `@list_type` are instance variables that live between list construction
and cleanup. If an exception occurs, state leaks. `item` silently returns self if called
outside a list block.

## Files
- `lib/coradoc/document_builder.rb` — refactor list/item methods
- `spec/coradoc/document_builder_spec.rb` — add edge case specs

## Changes
1. Replace `@list_items`/`@list_type` with local variable captured by closure
2. Raise ArgumentError if `item` called outside list context
3. Add specs for error case and nested lists
