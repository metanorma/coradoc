# coradoc-markdown schemas

Declarative model definitions (M1 of the PARG-bindings plan, metanorma/coradoc#303).

- `*.yml` — one file per model group; each class lists its attributes
  (type, `collection`, `default`) and the hand-written `behaviors` it takes.
- `Coradoc::Markdown::Schema.load_generated` compiles them through
  lutaml-model's schema pipeline (`Definitions::Model` → `CompiledOutput` →
  `ClassLoader`) into `Coradoc::Markdown::Generated`.
- `CORADOC_MARKDOWN_GENERATED=1` installs the generated classes in
  `Coradoc::Markdown` itself, replacing the hand-written model files.
- `Schema::Parity.diff` compares generated and hand-written classes
  (superclass, attribute order, type, collection, default).

## Behavior modules

Methods beyond attributes live in `Coradoc::Markdown::Behaviors::<Class>`.
Both the hand-written and the generated class **prepend** the module.
`prepend`, not `include`: lutaml defines attribute setters on the class
itself, so an included module could not override one and call `super`.
Class-level helpers go in a nested `ClassMethods`, extended from `prepended`.

## Known upstream gaps (worked around here)

- `ClassLoader` cannot load a nested `module_namespace`: class files are
  written under `dir/a/b/c/` but the registry requires `dir/c/`.
  `Schema::Loader::NestedClassLoader` mirrors the directory.
- `Renderers::MemberDecls#options_suffix` skips `default: false` (truthy
  check). `Schema::Definition::FalseDefault` renders the literal.
- `Definitions::Model` has no field for behavior modules; they are applied
  after load by `Schema::Loader`.
- The renderer always emits an `xml do ... end` block; markdown models have
  none by hand. It is harmless for parity (attributes are compared).
- LML carrier (lutaml-model#1033) is not available; YAML is the carrier.
