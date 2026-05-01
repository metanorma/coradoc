# 03: Define FormatModule interface contract

## Problem
`Coradoc.parse`, `serialize`, and `to_core` use `respond_to?` to probe for
`:parse_to_core`, `:parse`, `:serialize`, `:handles_model?`, `:to_core`.
There is no declared contract. A format module that forgets one method gets
a confusing runtime error instead of a clear registration-time error.

## Changes
1. Add `Coradoc::FormatModule` as a documentation module (or concern) listing
   the required interface: `parse_to_core(text)`, `serialize(model, **opts)`,
   `handles_model?(model)`, `to_core(model)`, `serialize?`
2. Add `register_format` validation that warns if the module doesn't implement
   the minimum required methods (`parse_to_core` or `parse`, and `serialize`)
3. Replace `respond_to?` guards in `Coradoc.parse`/`serialize` with direct calls
   (the validation at registration time makes the guards unnecessary)
4. Add specs for registration validation
