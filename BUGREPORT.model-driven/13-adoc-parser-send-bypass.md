# 13: AsciiDoc parser uses `send` instead of `public_send`

## Status: FIXED

- 3 `send` calls in `parser/base.rb` bypass access control
- All target methods are public, so `public_send` is safe


**Severity:** MEDIUM
**Location:** `coradoc-adoc/lib/coradoc/asciidoc/parser/base.rb`

## Evidence

Line 93: `send(rule_name, *args, **kwargs)`
Line 99: `send(dispatch_method)`
Line 143: `send(alias_name)`

All three call dynamically computed method names for Parslet rule dispatch.

## Fix

Replace all 3 `send` calls with `public_send`.
