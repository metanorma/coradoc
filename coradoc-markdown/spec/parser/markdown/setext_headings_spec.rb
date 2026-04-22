# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::BlockParser do
  describe 'Setext headings' do
    markdown_example 80, '
Foo *bar*
=========

Foo *bar*
---------
', [
  { heading: '=========', text: { ln: 'Foo *bar*' } }, # XXX: inline
  { heading: '---------', text: { ln: 'Foo *bar*' } } # XXX: inline
]

    markdown_example 81, '
Foo *bar
baz*
====
', [
  { heading: '====', text: [{ ln: 'Foo *bar' }, { ln: 'baz*' }] } # XXX: inline
]

    markdown_example 82, '
  Foo *bar
baz*
====
', [
  { heading: '====', text: [{ ln: 'Foo *bar' }, { ln: 'baz*' }] } # XXX: inline
]

    markdown_example 83, '
Foo
-------------------------

Foo
=
', [
  { heading: '-------------------------', text: { ln: 'Foo' } },
  { heading: '=', text: { ln: 'Foo' } }
]

    markdown_example 84, '
   Foo
---

  Foo
-----

  Foo
  ===
', [
  { heading: '---', text: { ln: 'Foo' } },
  { heading: '-----', text: { ln: 'Foo' } },
  { heading: '===', text: { ln: 'Foo' } }
]

    markdown_example 84, '
   Foo
---

  Foo
-----

  Foo
  ===
', [
  { heading: '---', text: { ln: 'Foo' } },
  { heading: '-----', text: { ln: 'Foo' } },
  { heading: '===', text: { ln: 'Foo' } }
]

    markdown_example 85, '
    Foo
    ---

    Foo
---
', [
  { code_block: [{ ln: 'Foo' }, { ln: '---' }, { ln: '' }, { ln: 'Foo' }] },
  { hr: true }
], strip: false # deletes significant indentation for the block

    markdown_example 86, '
Foo
   ----
', [
  { heading: '----', text: { ln: 'Foo' } }
]

    markdown_example 87, '
Foo
    ---
', [
  { p: [{ ln: 'Foo' }, { ln: '---' }] }
]

    markdown_example 88, '
Foo
= =

Foo
--- -
', [
  { p: [{ ln: 'Foo' }, { ln: '= =' }] },
  { p: { ln: 'Foo' } },
  { hr: true }
]

    markdown_example 89, '
Foo
-----
', [
  { heading: '-----', text: { ln: 'Foo' } } # XXX: inline
]

    markdown_example 90, '
Foo\
-----
', [
  { heading: '-----', text: { ln: 'Foo\\' } } # XXX: inline, escape
]

    markdown_example 91, '
`Foo
----
`

<a title="a lot
---
of dashes"/>
', [
  { heading: '----', text: { ln: '`Foo' } },
  { p: { ln: '`' } },
  { heading: '---', text: { ln: '<a title="a lot' } },
  { p: { ln: 'of dashes"/>' } }
]

    markdown_example 92, '
> Foo
---
', [
  { block_quote: { p: { ln: 'Foo' } } },
  { hr: true }
]

    markdown_example 93, '
> foo
bar
===
', [
  { block_quote: { p: [{ ln: 'foo' }, { ln: 'bar' }, { ln: '===' }] } }
]

    it 'parses example 94' do
      expect(subject.parse_with_debug('
- Foo
---')).to eq([
               { ul: { li: { p: { ln: 'Foo' } } } },
               { hr: true }
             ])
    end

    markdown_example 95, '
Foo
Bar
---
', [
  { heading: '---', text: [{ ln: 'Foo' }, { ln: 'Bar' }] }
]

    markdown_example 96, '
---
Foo
---
Bar
---
Baz
', [
  { hr: true },
  { heading: '---', text: { ln: 'Foo' } },
  { heading: '---', text: { ln: 'Bar' } },
  { p: { ln: 'Baz' } }
]

    markdown_example 97, '

====
', [
  { p: { ln: '====' } }
]

    markdown_example 98, '
---
---
  ', [
    { hr: true },
    { hr: true }
  ]

    it 'parses example 99' do
      expect(subject.parse_with_debug('
- foo
-----
        ')).to eq([
                    { ul: { li: { p: { ln: 'foo' } } } },
                    { hr: true }
                  ])
    end

    markdown_example 100, '
    foo
---
', [
  { code_block: { ln: 'foo' } },
  { hr: true }
], strip: false # deletes significant indentation for the block

    markdown_example 101, '
> foo
-----
', [
  { block_quote: { p: { ln: 'foo' } } },
  { hr: true }
]

    markdown_example 102, %q(
\> foo
------
), [
  { heading: '------', text: { ln: '> foo' } }
]

    markdown_example 103, '
Foo

bar
---
baz
', [
  { p: { ln: 'Foo' } },
  { heading: '---', text: { ln: 'bar' } },
  { p: { ln: 'baz' } }
]

    markdown_example 104, '
Foo
bar

---

baz
', [
  { p: [{ ln: 'Foo' }, { ln: 'bar' }] },
  { hr: true },
  { p: { ln: 'baz' } }
]

    markdown_example 105, '
Foo
bar
* * *
baz
', [
  { p: [{ ln: 'Foo' }, { ln: 'bar' }] },
  { hr: true },
  { p: { ln: 'baz' } }
]

    markdown_example 106, %q(
Foo
bar
\---
baz
), [
  { p: [{ ln: 'Foo' }, { ln: 'bar' }, { ln: '---' }, { ln: 'baz' }] }
]
  end
end
