require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown do
  describe "block quotes" do
    it "parses example 228" do
      expect(subject.parse_with_debug(%q(
> # Foo
> bar
> baz
      ))).to eq([
        {block_quote: [
          {heading: "#", text: "Foo"},
          {p: [{ln: "bar"}, {ln: "baz"}]},
        ]}
      ])
    end

    it "parses example 229" do
      expect(subject.parse_with_debug(%q(
># Foo
>bar
> baz
      ))).to eq([
        {block_quote: [
          {heading: "#", text: "Foo"},
          {p: [{ln: "bar"}, {ln: "baz"}]},
        ]}
      ])
    end

    it "parses example 230" do
      expect(subject.parse_with_debug(%q(
   > # Foo
   > bar
 > baz
      ))).to eq([
        {block_quote: [
          {heading: "#", text: "Foo"},
          {p: [{ln: "bar"}, {ln: "baz"}]},
        ]}
      ])
    end

    it "parses example 231" do
      expect(subject.parse_with_debug(%q(
    > # Foo
    > bar
    > baz
))).to eq([
        {code_block: [{ln: "> # Foo"}, {ln: "> bar"}, {ln: "> baz"}]},
      ])
    end

    it "parses example 232" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
> # Foo
> bar
baz
      ))).to eq([
        {block_quote: [
          {heading: "#", text: "Foo"},
          {p: [{ln: "bar"}, {ln: "baz"}]},
        ]}
      ])
    end

    it "parses example 233" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
> bar
baz
> foo
      ))).to eq([
        {block_quote: [
          {p: [{ln: "bar"}, {ln: "baz"}, {ln: "foo"}]},
        ]}
      ])
    end

    it "parses example 234" do
      expect(subject.parse_with_debug(%q(
> foo
---
      ))).to eq([
        {block_quote: {p: {ln: "foo"}}},
        {hr: true},
      ])
    end

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

    it "parses example 236" do
      expect(subject.parse_with_debug(%q(
>     foo
    bar
))).to eq([
        {block_quote: {code_block: {ln: "foo"}}},
        {code_block: {ln: "bar"}},
      ])
    end

    it "parses example 237" do
      pending "fenced code blocks"
      expect(subject.parse_with_debug(%q(
> ```
foo
```
      ))).to eq([
        {block_quote: {code_block: []}},
        {p: {ln: "foo"}},
        {code_block: []},
      ])
    end

    it "parses example 238" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
> foo
    - bar
      ))).to eq([
        {block_quote: {p: [{ln: "foo"}, {ln: "- bar"}]}},
      ])
    end

    it "parses example 239" do
      expect(subject.parse_with_debug(%q(
>
))).to eq([
        {block_quote: []},
      ])
    end

    it "parses example 240" do
      expect(subject.parse_with_debug(%q(
>
>  
> 
))).to eq([
        {block_quote: []},
      ])
    end

    it "parses example 241" do
      expect(subject.parse_with_debug(%q(
>
> foo
>  
      ))).to eq([
        {block_quote: [{p: {ln: "foo"}}]},
      ])
    end

    it "parses example 242" do
      expect(subject.parse_with_debug(%q(
> foo

> bar
      ))).to eq([
        {block_quote: {p: {ln: "foo"}}},
        {block_quote: {p: {ln: "bar"}}},
      ])
    end

    it "parses example 243" do
      expect(subject.parse_with_debug(%q(
> foo
> bar
      ))).to eq([
        {block_quote: {p: [{ln: "foo"}, {ln: "bar"}]}},
      ])
    end

    it "parses example 244" do
      expect(subject.parse_with_debug(%q(
> foo
>
> bar
      ))).to eq([
        {block_quote: [{p: {ln: "foo"}}, {p: {ln: "bar"}}]},
      ])
    end

    it "parses example 245" do
      expect(subject.parse_with_debug(%q(
foo
> bar
      ))).to eq([
        {p: {ln: "foo"}},
        {block_quote: {p: {ln: "bar"}}},
      ])
    end

    it "parses example 246" do
      expect(subject.parse_with_debug(%q(
> aaa
***
> bbb
      ))).to eq([
        {block_quote: {p: {ln: "aaa"}}},
        {hr: true},
        {block_quote: {p: {ln: "bbb"}}},
      ])
    end

    it "parses example 247" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
> bar
baz
      ))).to eq([
        {block_quote: {p: [{ln: "bar"}, {ln: "baz"}]}},
      ])
    end

    it "parses example 248" do
      expect(subject.parse_with_debug(%q(
> bar

baz
      ))).to eq([
        {block_quote: {p: {ln: "bar"}}},
        {p: {ln: "baz"}},
      ])
    end

    it "parses example 249" do
      expect(subject.parse_with_debug(%q(
> bar
>
baz
      ))).to eq([
        {block_quote: {p: {ln: "bar"}}},
        {p: {ln: "baz"}},
      ])
    end

    it "parses example 250" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
> > > foo
bar
      ))).to eq([
        {block_quote: {block_quote: {block_quote: {p: [{ln: "foo"}, {ln: "bar"}]}}}},
      ])
    end

    it "parses example 251" do
      pending "laziness"
      expect(subject.parse_with_debug(%q(
>>> foo
> bar
>>baz
      ))).to eq([
        {block_quote: {block_quote: {block_quote: {p: [{ln: "foo"}, {ln: "bar"}, {ln: "baz"}]}}}},
      ])
    end

    it "parses example 252" do
      expect(subject.parse_with_debug(%q(
>     code

>    not code
      ))).to eq([
        {block_quote: {code_block: {ln: "code"}}},
        {block_quote: {p: {ln: "not code"}}},
      ])
    end
  end
end

