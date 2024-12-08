require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "Setext headings" do
    markdown_example 80, %q(
Foo *bar*
=========

Foo *bar*
---------
), [
        {heading: "=========", text: {ln: "Foo *bar*"}}, # XXX: inline
        {heading: "---------", text: {ln: "Foo *bar*"}}, # XXX: inline
      ]

    markdown_example 81, %q(
Foo *bar
baz*
====
), [
        {heading: "====", text: [{ln: "Foo *bar"}, {ln: "baz*"}]}, # XXX: inline
      ]

    markdown_example 82, %q(
  Foo *bar
baz*	
====
), [
  {heading: "====", text: [{ln: "Foo *bar"}, {ln: "baz*\t"}]}, # XXX: inline, XXX: strip tab after
]

    markdown_example 83, %q(
Foo
-------------------------

Foo
=
), [
        {heading: "-------------------------", text: {ln: "Foo"}},
        {heading: "=", text: {ln: "Foo"}},
      ]

    markdown_example 84, %q(
   Foo
---

  Foo
-----

  Foo
  ===
), [
    {heading: "---", text: {ln: "Foo"}},
    {heading: "-----", text: {ln: "Foo"}},
    {heading: "===", text: {ln: "Foo"}},
  ]

    markdown_example 84, %q(
   Foo
---

  Foo
-----

  Foo
  ===
), [
    {heading: "---", text: {ln: "Foo"}},
    {heading: "-----", text: {ln: "Foo"}},
    {heading: "===", text: {ln: "Foo"}},
  ]

    markdown_example 85, %q(
    Foo
    ---

    Foo
---
), [
    {code_block: [{ln: "Foo"}, {ln: "---"}, {ln: ""}, {ln: "Foo"}]},
    {hr: true},
  ], strip: false # deletes significant indentation for the block

    markdown_example 86, %q(
Foo
   ----      
), [
  {heading: "----", text: {ln: "Foo"}},
]

    markdown_example 87, %q(
Foo
    ---
), [
{p: [{ln: "Foo"}, {ln: "---"}]},
      ]

    markdown_example 88, %q(
Foo
= =

Foo
--- -
), [
        {p: [{ln: "Foo"}, {ln: "= ="}]},
        {p: {ln: "Foo"}},
        {hr: true},
      ]

    markdown_example 89, %q(
Foo  
-----
), [
        {heading: "-----", text: {ln: "Foo  "}}, # XXX: inline
      ]

    markdown_example 90, %q(
Foo\
-----
), [
        {heading: "-----", text: {ln: "Foo\\"}}, # XXX: inline, escape
      ]

    markdown_example 91, %q(
`Foo
----
`

<a title="a lot
---
of dashes"/>
), [
    {heading: "----", text: {ln: "`Foo"}},
    {p: {ln: "`"}},
    {heading: "---", text: {ln: "<a title=\"a lot"}},
    {p: {ln: "of dashes\"/>"}},
  ]

    markdown_example 92, %q(
> Foo
---
), [
    {block_quote: {p: {ln: "Foo"}}},
    {hr: true},
]

    markdown_example 93, %q(
> foo
bar
===
), [
        {block_quote: {p: [{ln: "foo"}, {ln: "bar"}, {ln: "==="}]}},
      ]

    it "parses example 94" do
      pending "lists with laziness"
      expect(subject.parse_with_debug(%q(
- Foo
---))).to eq([
        {ul: {li: {text: "Foo"}}},
        {hr: true},
      ])
    end

    markdown_example 95, %q(
Foo
Bar
---
), [
    {heading: "---", text: [{ln: "Foo"}, {ln: "Bar"}]},
    ]

    markdown_example 96, %q(
---
Foo
---
Bar
---
Baz
), [
        {hr: true},
        {heading: "---", text: {ln: "Foo"}},
        {heading: "---", text: {ln: "Bar"}},
        {p: {ln: "Baz"}},
      ]

    markdown_example 97, %q(

====
), [
        {p: {ln: "===="}},
      ]

    markdown_example 98, %q(
---
---
  ), [
    {hr: true},
    {hr: true},
    ]

    it "parses example 99" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
- foo
-----
        ))).to eq([
        {ul: {li: {ln: "foo"}}},
        {hr: true},
      ])
    end

    markdown_example 100, %q(
    foo
---
), [
    {code_block: {ln: "foo"}},
    {hr: true},
  ], strip: false # deletes significant indentation for the block

    markdown_example 101, %q(
> foo
-----
), [
        {block_quote: {p: {ln: "foo"}}},
        {hr: true},
      ]

    markdown_example 102, %q(
\> foo
------
), [
        {heading: "------", text: {ln: "\\> foo"}},
      ]

    markdown_example 103, %q(
Foo

bar
---
baz
), [
        {p: {ln: "Foo"}},
        {heading: "---", text: {ln: "bar"}},
        {p: {ln: "baz"}},
      ]

    markdown_example 104, %q(
Foo
bar

---

baz
), [
        {p: [{ln: "Foo"}, {ln: "bar"}]},
        {hr: true},
        {p: {ln: "baz"}},
      ]

    markdown_example 105, %q(
Foo
bar
* * *
baz
), [
        {p: [{ln: "Foo"}, {ln: "bar"}]},
        {hr: true},
        {p: {ln: "baz"}},
      ]

    markdown_example 106, %q(
Foo
bar
\---
baz
), [
        {p: [{ln: "Foo"}, {ln: "bar"}, {ln: "\\---"}, {ln: "baz"}]}, # XXX: inline escapes
      ]
  end
end
