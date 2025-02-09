require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "block quotes" do
    markdown_example 228, %q(
> # Foo
> bar
> baz
), [
  {block_quote: [
    {heading: "#", text: "Foo"},
    {p: [{ln: "bar"}, {ln: "baz"}]},
  ]}
]

    markdown_example 229, %q(
># Foo
>bar
> baz
), [
  {block_quote: [
    {heading: "#", text: "Foo"},
    {p: [{ln: "bar"}, {ln: "baz"}]},
  ]}
]

    markdown_example 230, %q(
   > # Foo
   > bar
 > baz
), [
  {block_quote: [
    {heading: "#", text: "Foo"},
    {p: [{ln: "bar"}, {ln: "baz"}]},
  ]}
]

    markdown_example 231, %q(
    > # Foo
    > bar
    > baz
), [
  {code_block: [{ln: "> # Foo"}, {ln: "> bar"}, {ln: "> baz"}]},
], strip: false # deletes significant indentation for the block

    markdown_example 232, %q(
> # Foo
> bar
baz
      ), [
        {block_quote: [
          {heading: "#", text: "Foo"},
          {p: [{ln: "bar"}, {ln: "baz"}]},
        ]}
      ]

    markdown_example 233, %q(
> bar
baz
> foo
      ), [
        {block_quote: {p: [{ln: "bar"}, {ln: "baz"}, {ln: "foo"}]},
        }
      ]

    markdown_example 234, %q(
> foo
---
), [
  {block_quote: {p: {ln: "foo"}}},
  {hr: true},
]

    it "parses example 235" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
> - foo
- bar
      ))).to eq([
        {block_quote: {ul: {li: {p: {ln: "foo"}}}}},
        {ul: {li: {p: {ln: "foo"}}}},
      ])
    end

    markdown_example 236, %q(
>     foo
    bar
), [
        {block_quote: {code_block: {ln: "foo"}}},
        {code_block: {ln: "bar"}},
      ]

    markdown_example 237, %q(
> ```
foo
```
), [
        {block_quote: {code_block: []}},
        {p: {ln: "foo"}},
        {code_block: []},
      ]

    markdown_example 238, %q(
> foo
    - bar
), [
        {block_quote: {p: [{ln: "foo"}, {ln: "- bar"}]}},
      ]

    markdown_example 239, %q(
>
), [
        {block_quote: ""},
      ]

    markdown_example 240, %q(
>
>  
> 
), [
        {block_quote: ""},
      ]

    markdown_example 241, %q(
>
> foo
>  
), [
  {block_quote: [{p: {ln: "foo"}}]},
]

    markdown_example 242, %q(
> foo

> bar
), [
  {block_quote: {p: {ln: "foo"}}},
  {block_quote: {p: {ln: "bar"}}},
]

    markdown_example 243, %q(
> foo
> bar
), [
  {block_quote: {p: [{ln: "foo"}, {ln: "bar"}]}},
]

    markdown_example 244, %q(
> foo
>
> bar
), [
  {block_quote: [{p: {ln: "foo"}}, {p: {ln: "bar"}}]},
]

    markdown_example 245, %q(
foo
> bar
), [
  {p: {ln: "foo"}},
  {block_quote: {p: {ln: "bar"}}},
]

    markdown_example 246, %q(
> aaa
***
> bbb
), [
  {block_quote: {p: {ln: "aaa"}}},
  {hr: true},
  {block_quote: {p: {ln: "bbb"}}},
]

    markdown_example 247, %q(
> bar
baz
      ), [
        {block_quote: {p: [{ln: "bar"}, {ln: "baz"}]}},
      ]

    markdown_example 248, %q(
> bar

baz
), [
  {block_quote: {p: {ln: "bar"}}},
  {p: {ln: "baz"}},
]

    markdown_example 249, %q(
> bar
>
baz
), [
  {block_quote: {p: {ln: "bar"}}},
  {p: {ln: "baz"}},
]

    markdown_example 250, %q(
> > > foo
bar
      ), [
        {block_quote: {block_quote: {block_quote: {p: [{ln: "foo"}, {ln: "bar"}]}}}},
      ]

    markdown_example 251, %q(
>>> foo
> bar
>>baz
      ), [
        {block_quote: {block_quote: {block_quote: {p: [{ln: "foo"}, {ln: "bar"}, {ln: "baz"}]}}}},
      ]

    markdown_example 252, %q(
>     code

>    not code
), [
  {block_quote: {code_block: {ln: "code"}}},
  {block_quote: {p: {ln: "not code"}}},
]

    markdown_example "252 extended", %q(
>     code
>     multi line code!

>    not code
), [
  {block_quote: {code_block: [{ln: "code"}, {ln: "multi line code!"}]}},
  {block_quote: {p: {ln: "not code"}}},
]
  end
end

