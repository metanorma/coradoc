# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::BlockParser do
  describe 'thematic breaks' do
    markdown_example 43, '
***
---
___
', [
  { hr: true },
  { hr: true },
  { hr: true }
]

    markdown_example 44, '
+++
', [
  { p: { ln: '+++' } }
]

    markdown_example 45, '
===
', [
  { p: { ln: '===' } }
]

    markdown_example 46, '
--
**
__
', [
  { p: [{ ln: '--' }, { ln: '**' }, { ln: '__' }] }
]

    markdown_example 47, '
 ***
  ***
   ***
', [
  { hr: true },
  { hr: true },
  { hr: true }
]

    markdown_example 48, '
    ***
', [
  { code_block: { ln: '***' } }
], strip: false # deletes significant indentation for the block

    markdown_example 49, '
Foo
    ***
', [
  { p: [{ ln: 'Foo' }, { ln: '***' }] }
]

    markdown_example 50, '
_____________________________________
', [
  { hr: true }
]

    markdown_example 51, '
 - - -
', [
  { hr: true }
]

    markdown_example 52, '
 **  * ** * ** * **
', [
  { hr: true }
]

    markdown_example 53, '
-     -      -      -
', [
  { hr: true }
]

    markdown_example 54, '
- - - -
', [
  { hr: true }
]

    markdown_example 55, '
_ _ _ _ a

a------

---a---
', [
  { p: { ln: '_ _ _ _ a' } },
  { p: { ln: 'a------' } },
  { p: { ln: '---a---' } }
]

    markdown_example 56, '
 *-*
      ', [
        { p: { ln: { em: '-' } } }
      ]

    it 'parses example 57' do
      expect(subject.parse_with_debug('
- foo
***
- bar
      ')).to eq([
                  { ul: { li: { p: { ln: 'foo' } } } },
                  { hr: true },
                  { ul: { li: { p: { ln: 'bar' } } } }
                ])
    end

    markdown_example 58, '
Foo
***
bar
', [
  { p: { ln: 'Foo' } },
  { hr: true },
  { p: { ln: 'bar' } }
]

    markdown_example 59, '
Foo
---
bar
', [
  { heading: '---', text: { ln: 'Foo' } },
  { p: { ln: 'bar' } }
]

    it 'parses example 60' do
      expect(subject.parse_with_debug('
* Foo
* * *
* Bar
      ')).to eq([
                  { ul: { li: { p: { ln: 'Foo' } } } },
                  { hr: true },
                  { ul: { li: { p: { ln: 'Bar' } } } }
                ])
    end

    it 'parses example 61' do
      expect(subject.parse_with_debug('
- Foo
- * * *
      ')).to eq([
                  { ul: [{ li: { p: { ln: 'Foo' } } }, { li: { hr: true } }] }
                ])
    end
  end
end
