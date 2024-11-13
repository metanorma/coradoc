require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown do
  describe "thematic breaks" do
    it "parses example 43" do
      expect(subject.parse_with_debug(%q(
***
---
___
      ))).to eq([
        {hr: true},
        {hr: true},
        {hr: true},
      ])
    end

    it "parses example 44" do
      expect(subject.parse_with_debug(%q(
+++
      ))).to eq([
        {p: {ln: "+++"}}
      ])
    end

    it "parses example 45" do
      expect(subject.parse_with_debug(%q(
===
      ))).to eq([
        {p: {ln: "==="}}
      ])
    end

    it "parses example 46" do
      expect(subject.parse_with_debug(%q(
--
**
__
      ))).to eq([
        {p: [{ln: "--"}, {ln: "**"}, {ln: "__"}]}
      ])
    end

    it "parses example 47" do
      expect(subject.parse_with_debug(%q(
 ***
  ***
   ***
      ))).to eq([
        {hr: true},
        {hr: true},
        {hr: true},
      ])
    end

    it "parses example 48" do
      expect(subject.parse_with_debug(%q(
    ***
))).to eq([
        {code_block: {ln: "***"}}
      ])
    end

    it "parses example 49" do
      pending "eat paragraph line initial space"
      expect(subject.parse_with_debug(%q(
Foo
    ***
      ))).to eq([
        {p: [{ln: "Foo"}, {ln: "***"}]}
      ])
    end

    it "parses example 50" do
      expect(subject.parse_with_debug(%q(
_____________________________________
      ))).to eq([
        {hr: true}
      ])
    end

    it "parses example 51" do
      expect(subject.parse_with_debug(%q(
 - - -
      ))).to eq([
        {hr: true}
      ])
    end

    it "parses example 52" do
      expect(subject.parse_with_debug(%q(
 **  * ** * ** * **
      ))).to eq([
        {hr: true}
      ])
    end

    it "parses example 53" do
      expect(subject.parse_with_debug(%q(
-     -      -      -
      ))).to eq([
        {hr: true}
      ])
    end

    it "parses example 54" do
      expect(subject.parse_with_debug(%q(
- - - -    
      ))).to eq([
        {hr: true}
      ])
    end

    it "parses example 55" do
      expect(subject.parse_with_debug(%q(
_ _ _ _ a

a------

---a---
      ))).to eq([
        {p: {ln: "_ _ _ _ a"}},
        {p: {ln: "a------"}},
        {p: {ln: "---a---"}},
      ])
    end

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

    it "parses example 58" do
      expect(subject.parse_with_debug(%q(
Foo
***
bar
      ))).to eq([
        {p: {ln: "Foo"}},
        {hr: true},
        {p: {ln: "bar"}},
      ])
    end

    it "parses example 59" do
      pending "setext headings"
      expect(subject.parse_with_debug(%q(
Foo
---
bar
      ))).to eq([
        {h2: "Foo"},
        {p: {ln: "bar"}},
      ])
    end

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
