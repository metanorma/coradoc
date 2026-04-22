# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::BlockParser do
  describe 'block quotes' do
    markdown_example 228, '
> # Foo
> bar
> baz
', [
  { block_quote: [
    { heading: '#', text: 'Foo' },
    { p: [{ ln: 'bar' }, { ln: 'baz' }] }
  ] }
]

    markdown_example 229, '
># Foo
>bar
> baz
', [
  { block_quote: [
    { heading: '#', text: 'Foo' },
    { p: [{ ln: 'bar' }, { ln: 'baz' }] }
  ] }
]

    markdown_example 230, '
   > # Foo
   > bar
 > baz
', [
  { block_quote: [
    { heading: '#', text: 'Foo' },
    { p: [{ ln: 'bar' }, { ln: 'baz' }] }
  ] }
]

    markdown_example 231, '
    > # Foo
    > bar
    > baz
', [
  { code_block: [{ ln: '> # Foo' }, { ln: '> bar' }, { ln: '> baz' }] }
], strip: false # deletes significant indentation for the block

    markdown_example 232, '
> # Foo
> bar
baz
      ', [
        { block_quote: [
          { heading: '#', text: 'Foo' },
          { p: [{ ln: 'bar' }, { ln: 'baz' }] }
        ] }
      ]

    markdown_example 233, '
> bar
baz
> foo
      ', [
        { block_quote: { p: [{ ln: 'bar' }, { ln: 'baz' }, { ln: 'foo' }] } }
      ]

    markdown_example 234, '
> foo
---
', [
  { block_quote: { p: { ln: 'foo' } } },
  { hr: true }
]

    it 'parses example 235' do
      expect(subject.parse_with_debug('
> - foo
- bar
      ')).to eq([
                  { block_quote: { ul: { li: { p: { ln: 'foo' } } } } },
                  { ul: { li: { p: { ln: 'bar' } } } }
                ])
    end

    markdown_example 236, '
>     foo
    bar
', [
  { block_quote: { code_block: { ln: 'foo' } } },
  { code_block: { ln: 'bar' } }
]

    markdown_example 237, '
> ```
foo
```
', [
  { block_quote: { code_block: [] } },
  { p: { ln: 'foo' } },
  { code_block: [] }
]

    markdown_example 238, '
> foo
    - bar
', [
  { block_quote: { p: [{ ln: 'foo' }, { ln: '- bar' }] } }
]

    markdown_example 239, '
>
', [
  { block_quote: '' }
]

    markdown_example 240, '
>
>
>
', [
  { block_quote: '' }
]

    markdown_example 241, '
>
> foo
>
', [
  { block_quote: [{ p: { ln: 'foo' } }] }
]

    markdown_example 242, '
> foo

> bar
', [
  { block_quote: { p: { ln: 'foo' } } },
  { block_quote: { p: { ln: 'bar' } } }
]

    markdown_example 243, '
> foo
> bar
', [
  { block_quote: { p: [{ ln: 'foo' }, { ln: 'bar' }] } }
]

    markdown_example 244, '
> foo
>
> bar
', [
  { block_quote: [{ p: { ln: 'foo' } }, { p: { ln: 'bar' } }] }
]

    markdown_example 245, '
foo
> bar
', [
  { p: { ln: 'foo' } },
  { block_quote: { p: { ln: 'bar' } } }
]

    markdown_example 246, '
> aaa
***
> bbb
', [
  { block_quote: { p: { ln: 'aaa' } } },
  { hr: true },
  { block_quote: { p: { ln: 'bbb' } } }
]

    markdown_example 247, '
> bar
baz
      ', [
        { block_quote: { p: [{ ln: 'bar' }, { ln: 'baz' }] } }
      ]

    markdown_example 248, '
> bar

baz
', [
  { block_quote: { p: { ln: 'bar' } } },
  { p: { ln: 'baz' } }
]

    markdown_example 249, '
> bar
>
baz
', [
  { block_quote: { p: { ln: 'bar' } } },
  { p: { ln: 'baz' } }
]

    markdown_example 250, '
> > > foo
bar
      ', [
        { block_quote: { block_quote: { block_quote: { p: [{ ln: 'foo' }, { ln: 'bar' }] } } } }
      ]

    markdown_example 251, '
>>> foo
> bar
>>baz
      ', [
        { block_quote: { block_quote: { block_quote: { p: [{ ln: 'foo' }, { ln: 'bar' }, { ln: 'baz' }] } } } }
      ]

    markdown_example 252, '
>     code

>    not code
', [
  { block_quote: { code_block: { ln: 'code' } } },
  { block_quote: { p: { ln: 'not code' } } }
]

    markdown_example '252 extended', '
>     code
>     multi line code!

>    not code
', [
  { block_quote: { code_block: [{ ln: 'code' }, { ln: 'multi line code!' }] } },
  { block_quote: { p: { ln: 'not code' } } }
]
  end
end
