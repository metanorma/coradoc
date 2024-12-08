require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "indented code blocks" do
    markdown_example 107, %q(
    a simple
      indented code block), [
  {code_block: [{ln: "a simple"}, {ln: "  indented code block"}]},
], strip: false # deletes significant indentation for the block

    it "parses example 108" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
  - foo

    bar))).to eq([
        {ul: {li: {p: [{ln: "foo"}, {ln: "bar"}]}}},
      ])
    end

    it "parses example 109" do
      pending "lists"
      expect(subject.parse_with_debug(%q(
1.  foo

    - bar))).to eq([
        {ol: {li: [{p: {ln: "foo"}}, {ul: {li: "bar"}}]}},
      ])
    end

    markdown_example 110, %q(
    <a/>
    *hi*

    - one), [
{code_block: [{ln: "<a/>"}, {ln: "*hi*"}, {ln: ""}, {ln: "- one"}]},
      ], strip: false # deletes significant indentation for the block

    markdown_example 111, %q(
    chunk1

    chunk2
  
 
 
    chunk3), [
{code_block: [{ln: "chunk1"}, {ln: ""}, {ln: "chunk2"}, {ln: ""}, {ln: ""}, {ln: ""}, {ln: "chunk3"}]},
      ], strip: false # deletes significant indentation for the block

    markdown_example 112, %q(
    chunk1
      
      chunk2), [
  {code_block: [{ln: "chunk1"}, {ln: "  "}, {ln: "  chunk2"}]},
], strip: false # deletes significant indentation for the block

    markdown_example 113, %q(
Foo
    bar
), [
  {p: [{ln: "Foo"}, {ln: "bar"}]},
]

    markdown_example 114, %q(
    foo
bar), [
        {code_block: {ln: "foo"}},
        {p: {ln: "bar"}},
      ], strip: false # deletes significant indentation for the block

    it "parses example 115" do
      pending "setext headings"
      expect(subject.parse_with_debug(%q(
# Heading
    foo
Heading
------
    foo
----))).to eq([
        {heading: "#", text: "Heading"},
        {code_block: {ln: "foo"}},
        {heading: "------", text: "Heading"},
        {code_block: {ln: "foo"}},
        {hr: true},
      ])
    end

    markdown_example 116, %q(
        foo
    bar), [
{code_block: [{ln: "    foo"}, {ln: "bar"}]},
      ], strip: false # deletes significant indentation for the block

    markdown_example 117, %q(

    
    foo
    ), [
  {code_block: {ln: "foo"}},
], strip: false # deletes significant indentation for the block

    markdown_example 118, %q(
    foo  ), [
  {code_block: {ln: "foo  "}},
], strip: false # deletes significant indentation for the block
  end
end
