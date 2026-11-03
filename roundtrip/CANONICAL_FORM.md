# Round-trip harness and canonical-form policy

Guard for the CoreModel hub (stage 2↔3 seam): every format's
`ToCoreModel` / `FromCoreModel` pair must be a faithful round trip.
Issue: metanorma/coradoc#304.

## Run it

    bundle exec rake roundtrip              # both formats
    bundle exec rake roundtrip:adoc         # one format
    bundle exec rake roundtrip:markdown
    CORADOC_ROUNDTRIP_EXTRA=~/mn-samples bundle exec rake roundtrip   # extra corpus

## What is checked, per input text `T` in format `F`

    core1 = parse(T)     T1 = serialize(core1)
    core2 = parse(T1)    T2 = serialize(core2)

| Property | Assertion | Stage in a failure |
|---|---|---|
| Parse / serialize / re-parse do not raise | — | `parse`, `serialize`, `reparse` |
| Model stability | `projection(core1) == projection(core2)` | `model` |
| Canonical fixed point | `T2 == T1` | `canonical` |
| Termination | each case finishes in 20 s (`CORADOC_ROUNDTRIP_TIMEOUT`) | `timeout` |

## What "identity" means: the canonical form

Identity is **not** `T == T1`. Source text has many spellings of one
construct (`_x_` and `*x*` for emphasis, `*`/`-`/`+` list markers, setext vs
ATX headings, blank-line runs). Requiring byte equality with the input would
fail every normalization the serializer legitimately performs.

Instead `T1 = serialize(parse(T))` **is the canonical form of `T`**, and the
contract is that canonicalization is stable:

1. Parsing the canonical form gives the same document (model stability).
2. Serializing that document gives the canonical form again (fixed point).

A normalization (marker choice, spacing) is therefore allowed; a change of
meaning, a loss of content, or output that keeps drifting is a failure.

`projection` is the CoreModel reduced to plain data: every attribute of every
node, `nil`/empty omitted, **except** `source_line` (positional bookkeeping,
not meaning). Anything else that changes is a model difference.

## Reading a failure

    asciidoc:README.adoc [model] at $.children[1].lines[0]
    CoreModel changed on re-parse of the serialized output
    first: "RubyGems Version"
    again: "RubyGems Version License ..."
    near canonical output:
       1| = Coradoc
       2| image:https://...[RubyGems Version] image:https://...

The case id names the file (or `edge/<name>` for generated cases), the path
is the CoreModel location of the first difference (`canonical` failures give a
line number instead), and the excerpt shows the offending text.

## Corpus

- `corpus.yml`: fixture globs, relative to the repo root, per format.
- `CORADOC_ROUNDTRIP_EXTRA`: any directory; `*.adoc` run as AsciiDoc,
  `*.md`/`*.markdown` as Markdown. Use it for mn-samples and plateau, which
  are not vendored here.
- `Coradoc::Roundtrip::EdgeCases`: generated edge cases (empty input, unicode,
  nesting, markers, tables, frontmatter, ...). Add a construct there when a
  bug is found that no fixture isolates.

## Known failures

`known_failures.yml` lists the cases that fail today, with a reason. They run
as RSpec `pending`: a listed case that starts passing **fails the suite**
until its entry is removed, so the list can only shrink. Every entry is
currently `untriaged:` — the baseline was captured mechanically
(`rake roundtrip:baseline`); replacing each with a root cause is the work this
harness exists to drive. Never add an entry to make CI green for a new
regression.

## Gate for dependent work

The bindings rewrite (M2/M3) and any CoreModel change must keep this suite
green: no new failures, and ideally fewer known failures than before.
