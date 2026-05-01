# 02: Format gems drive format detection (OCP fix)

## Problem
FORMAT_ALIASES, EXTENSION_FORMATS, and BINARY_FORMATS are hardcoded in
`coradoc.rb`. Adding a new format (e.g., LaTeX) requires editing the core gem.
Format gems already call `register_format(:name, module, extensions: [...])` but
the core ignores this data and uses its own hardcoded lists.

## Changes
1. Add `aliases`, `extensions`, `binary` to registration options
2. Remove `FORMAT_ALIASES`, `EXTENSION_FORMATS`, `BINARY_FORMATS` constants
3. `detect_format(filename)` queries registered format options
4. `normalize_format(name)` queries registered format aliases
5. `binary_format?(format)` queries registered format binary flag
6. Each format gem passes its aliases/extensions/binary during `register_format`
7. Update specs to remove constant assertions, test dynamic detection
