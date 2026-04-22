# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Parser::BlockParser do
  describe 'ATX headings' do
    markdown_example 62, '
# foo
## foo
### foo
#### foo
##### foo
###### foo
', [
  { heading: '#', text: 'foo' },
  { heading: '##', text: 'foo' },
  { heading: '###', text: 'foo' },
  { heading: '####', text: 'foo' },
  { heading: '#####', text: 'foo' },
  { heading: '######', text: 'foo' }
]

    markdown_example 63, '
####### foo
', [
  { p: { ln: '####### foo' } }
]

    markdown_example 64, '
#5 bolt

#hashtag
', [
  { p: { ln: '#5 bolt' } },
  { p: { ln: '#hashtag' } }
]

    markdown_example 65, %q(\# foo
), [
  { p: { ln: '# foo' } }
]

    markdown_example 66, %q(\## foo
), [
  { p: { ln: '## foo' } }
]

    markdown_example 67, '
#                  foo
', [
  { heading: '#', text: 'foo' }
]

    markdown_example 68, '
 ### foo
  ## foo
   # foo
', [
  { heading: '###', text: 'foo' },
  { heading: '##', text: 'foo' },
  { heading: '#', text: 'foo' }
]

    markdown_example 69, '
    # foo
', [
  { code_block: { ln: '# foo' } }
], strip: false # deletes significant indentation for the block

    markdown_example 70, '
foo
    # bar
', [
  { p: [{ ln: 'foo' }, { ln: '# bar' }] }
]

    markdown_example 71, '
## foo ##
  ###   bar    ###
', [
  { heading: '##', text: 'foo' },
  { heading: '###', text: 'bar' }
]

    markdown_example 72, '
# foo ##################################
##### foo ##
', [
  { heading: '#', text: 'foo' },
  { heading: '#####', text: 'foo' }
]

    markdown_example 73, '
### foo ###
', [
  { heading: '###', text: 'foo' }
]

    markdown_example 74, '
### foo ### b
', [
  { heading: '###', text: 'foo ### b' }
]

    markdown_example 75, '
# foo#
', [
  { heading: '#', text: 'foo#' }
]

    it 'parses example 76' do
      result = subject.parse_with_debug(%q(
### foo \###
## foo #\##
# foo \#
      ))
      # Apply post-processing for escape sequences
      result = Coradoc::Markdown::Parser::AstProcessor.process(result)
      # Convert Parslet::Slice to strings for comparison
      result = MarkdownExampleHelper.convert_slices_to_strings(result)
      expect(result).to eq([
                             { heading: '###', text: 'foo ###' },
                             { heading: '##', text: 'foo ###' },
                             { heading: '#', text: 'foo #' }
                           ])
    end

    markdown_example 77, '
****
## foo
****
', [
  { hr: true },
  { heading: '##', text: 'foo' },
  { hr: true }
]

    markdown_example 78, '
Foo bar
# baz
Bar foo
', [
  { p: { ln: 'Foo bar' } },
  { heading: '#', text: 'baz' },
  { p: { ln: 'Bar foo' } }
]

    markdown_example 79, '
##
#
### ###
', [
  { heading: '##' },
  { heading: '#' },
  { heading: '###' }
]
  end
end
