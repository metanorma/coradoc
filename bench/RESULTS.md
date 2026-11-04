# Plateau corpus parse benchmark (coradoc#308)

Corpus: metanorma/mn-samples-plateau @ 5609b32 (Project PLATEAU, MLIT), the
`*.adoc` files of at most 5000 bytes: 496 of 793 files, about 0.6 MB. Larger files
were left out because the parser is slow on them (a 21 MB file, and several
over 300 KB, would not finish in reasonable time) and the machine had ~1 GB free.
Six files (12 with duplicates under sources-static/) hit pathological grammar
backtracking (>8-30 s on a ~1-2 KB file) in OLD and NEW alike; a 15 s (8 s in the timed
runs) hard per-file limit marks them `timeout`.

OLD = 0a72e73 (parent of #316). NEW = 0ad2aff (PR #324). Ruby 3.4.8, same gem
set for both (`lutaml-model 0.8.164`, `parsanol 1.3.133`, `leptris 1.9.406.1`),
single process, files run one at a time in a forked child, OLD and NEW
interleaved, 3 runs, median of per-run totals. Machine was shared, so absolute
times are noisy.

| stage | OLD | NEW | NEW/OLD |
|---|---|---|---|
| 1 grammar -> AST | 99.9 s | 100.0 s | 1.00 |
| 2 AST -> AsciiDoc model | 18.6 s | 16.5 s | 0.89 |
| model -> CoreModel | 22.8 s | 22.8 s | 1.00 |
| total | 141.3 s | 139.3 s | 0.99 (3.5 vs 3.6 files/s) |

Most of the time is stage 1 (the grammar, unchanged by the binding work), and
a few slow files dominate. Stage 2 is the layer the binding work changed.

## Output identity (OLD vs NEW, per file, 496 files)

- AST (stage 1): 496/496 identical.
- AsciiDoc model (stage 2): 495/496 identical.
- CoreModel, raw YAML dump: 76/496 identical. OLD leaks
  `Parser::PositionedString` (a String that carries its whole `source_input`) and
  parsanol `LineCache` objects into the CoreModel; NEW holds plain strings. With
  PositionedString collapsed to its text, 486/496 are identical; the remaining
  9 were not diagnosed (one inspected showed only the title PositionedString).
- Regression in NEW: `sources/001-v5/sections/section-04/section-25.adoc` raises
  `TypeError: no implicit conversion of Symbol into Integer` in
  `Bindings::StructureHooks.comment_line` (coradoc-adoc structure_hooks.rb:103,
  `raw[:comment_text]` on a String). OLD parses it.
- In the three timed runs, a few ~4 s files flipped between ok and the 8 s
  timeout in either side; that is load noise (the 30 s identity pass has 12
  timeouts in both).

Reproduce: `bench/run.sh CORPUS out.json` inside a bundle for each checkout,
then `ruby bench/compare.rb old1.json old2.json old3.json -- new1.json new2.json new3.json`.
