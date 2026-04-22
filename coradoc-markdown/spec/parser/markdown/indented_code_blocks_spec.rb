# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::BlockParser do
  describe 'indented code blocks' do
    markdown_example 107, '
    a simple
      indented code block', [
        { code_block: [{ ln: 'a simple' }, { ln: '  indented code block' }] }
      ], strip: false # deletes significant indentation for the block

    markdown_example 108, '
  - foo
    bar', [
      { ul: { li: { p: [{ ln: 'foo' }, { ln: 'bar' }] } } }
    ], strip: false

    markdown_example 109, '
1.  foo
    - bar', [
      { ol: { li: [{ p: { ln: 'foo' } }, { ul: { li: 'bar' } }] } }
    ], strip: false

    markdown_example 110, '
    <a/>
    *hi*

    - one', [
      { code_block: [{ ln: '<a/>' }, { ln: '*hi*' }, { ln: '' }, { ln: '- one' }] }
    ], strip: false # deletes significant indentation for the block

    markdown_example 111, '
    chunk1

    chunk2



    chunk3', [
      { code_block: [{ ln: 'chunk1' }, { ln: '' }, { ln: 'chunk2' }, { ln: '' }, { ln: '' }, { ln: '' }, { ln: 'chunk3' }] }
    ], strip: false # deletes significant indentation for the block

    markdown_example 112, '
    chunk1

      chunk2', [
        { code_block: [{ ln: 'chunk1' }, { ln: '' }, { ln: '  chunk2' }] }
      ], strip: false # deletes significant indentation for the block

    markdown_example 113, '
Foo
    bar
', [
  { p: [{ ln: 'Foo' }, { ln: 'bar' }] }
]

    markdown_example 114, '
    foo
bar', [
  { code_block: { ln: 'foo' } },
  { p: { ln: 'bar' } }
], strip: false # deletes significant indentation for the block

    it 'parses example 115' do
      expect(subject.parse_with_debug('
# Heading
    foo
Heading
------
    foo
----')).to eq([
                { heading: '#', text: 'Heading' },
                { code_block: { ln: 'foo' } },
                { heading: '------', text: { ln: 'Heading' } },
                { code_block: { ln: 'foo' } },
                { hr: true }
              ])
    end

    markdown_example 116, '
        foo
    bar', [
      { code_block: [{ ln: '    foo' }, { ln: 'bar' }] }
    ], strip: false # deletes significant indentation for the block

    markdown_example 117, '


    foo
    ', [
      { code_block: { ln: 'foo' } }
    ], strip: false # deletes significant indentation for the block

    markdown_example 118, '
    foo  ', [
      { code_block: { ln: 'foo  ' } }
    ], strip: false # deletes significant indentation for the block
  end
end
