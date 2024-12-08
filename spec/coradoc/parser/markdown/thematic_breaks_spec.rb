require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "thematic breaks" do
    markdown_example 43, %q(
***
---
___
), [
  {hr: true},
  {hr: true},
  {hr: true},
]

    markdown_example 44, %q(
+++
), [
  {p: {ln: "+++"}}
]

    markdown_example 45, %q(
===
), [
  {p: {ln: "==="}}
]

    markdown_example 46, %q(
--
**
__
), [
  {p: [{ln: "--"}, {ln: "**"}, {ln: "__"}]}
]

    markdown_example 47, %q(
 ***
  ***
   ***
), [
  {hr: true},
  {hr: true},
  {hr: true},
]

    markdown_example 48, %q(
    ***
), [
  {code_block: {ln: "***"}}
], strip: false # deletes significant indentation for the block

    markdown_example 49, %q(
Foo
    ***
), [
  {p: [{ln: "Foo"}, {ln: "***"}]}
]

    markdown_example 50, %q(
_____________________________________
), [
  {hr: true}
]

    markdown_example 51, %q(
 - - -
), [
  {hr: true}
]

    markdown_example 52, %q(
 **  * ** * ** * **
), [
  {hr: true}
]

    markdown_example 53, %q(
-     -      -      -
), [
  {hr: true}
]

    markdown_example 54, %q(
- - - -    
), [
  {hr: true}
]

    markdown_example 55, %q(
_ _ _ _ a

a------

---a---
), [
  {p: {ln: "_ _ _ _ a"}},
  {p: {ln: "a------"}},
  {p: {ln: "---a---"}},
]

    it "parses example 56" do
      pending "inlines"
      expect(subject.parse_with_debug(%q(
 *-*
      ))).to eq([
        {p: {ln: {em: "-"}}},
      ])
    end

    it "parses example 57" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
- foo
***
- bar
      ))).to eq([
        {ul: {li: {p: {ln: "foo"}}}},
        {hr: true},
        {ul: {li: {p: {ln: "bar"}}}},
      ])
    end

    markdown_example 58, %q(
Foo
***
bar
), [
  {p: {ln: "Foo"}},
  {hr: true},
  {p: {ln: "bar"}},
]

    markdown_example 59, %q(
Foo
---
bar
), [
  {heading: "---", text: {ln: "Foo"}},
  {p: {ln: "bar"}},
]

    it "parses example 60" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
* Foo
* * *
* Bar
      ))).to eq([
        {ul: {li: {p: {ln: "Foo"}}}},
        {hr: true},
        {ul: {li: {p: {ln: "Bar"}}}},
      ])
    end

    it "parses example 61" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
- Foo
- * * *
      ))).to eq([
        {ul: [{li: {p: {ln: "Foo"}}}, {li: {hr: true}}]}
      ])
    end

  end
end
