# 01: Thin CLI wrapper — move all business logic to API

## Problem
CLI contains business logic that belongs in the Coradoc API:
1. `detect_output_format` defaults to `:html` — business decision, not CLI presentation
2. `build_options` knows HTML-specific options — OCP violation
3. `convert` command duplicates binary/text routing that `Coradoc.convert_file` already handles
4. `formats` command probes `respond_to?(:parse_to_core)` — format introspection is API logic
5. `info` command computes file size/line count — could be in `document_stats`
6. File existence checking repeated 4 times — API should raise `FileNotFoundError`
7. Dead one-line wrappers: `registered_formats`, `describe_element`, `binary_format?`, `parse_from_file`

## Changes
1. Add `Coradoc.parse_format?(format)` — returns true if format can parse
2. Add `Coradoc.default_format` — returns `:html` (configurable)
3. Add `Coradoc.resolve_format(path, format:, direction:)` — handles defaults and detection
4. Remove `build_options` — pass all CLI options through, let serialize filter
5. Simplify `convert` command to single `Coradoc.convert_file` call
6. Add `Coradoc.file_info(path)` for file metadata (size, lines)
7. Remove dead wrapper methods
8. Update specs
