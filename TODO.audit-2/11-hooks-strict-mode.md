# TODO 11: Hooks strict mode for failures

Status: DONE

## Problem
`invoke_hook` rescues StandardError and only logs a warning. Hook typos silently produce
wrong output. No way to detect broken hooks in tests.

## Files
- `lib/coradoc/hooks.rb` — add strict mode configuration
- `spec/hooks_spec.rb` — add spec for strict mode

## Changes
1. Add `Hooks.strict_mode = true/false` class-level setting (default: false)
2. In `invoke_hook`, re-raise when strict mode is enabled
3. Add spec for strict mode behavior
