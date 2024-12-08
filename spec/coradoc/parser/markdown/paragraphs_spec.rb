require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "paragraphs" do
    markdown_example 219, %q(
aaa

bbb), [
        {p: {ln: "aaa"}},
        {p: {ln: "bbb"}},
      ]

    markdown_example 220, %q(
aaa
bbb

ccc
ddd), [
        {p: [{ln: "aaa"}, {ln: "bbb"}]},
        {p: [{ln: "ccc"}, {ln: "ddd"}]},
      ]

    markdown_example 221, %q(
aaa


bbb), [
        {p: {ln: "aaa"}},
        {p: {ln: "bbb"}},
      ]

    markdown_example 222, %q(
  aaa
 bbb), [
      {p: [{ln: "aaa"}, {ln: "bbb"}]},
    ]

    markdown_example 223, %q(
aaa
       bbb
                                 ccc), [
            {p: [{ln: "aaa"}, {ln: "bbb"}, {ln: "ccc"}]},
          ]

    markdown_example 224, %q(
   aaa
bbb), [
        {p: [{ln: "aaa"}, {ln: "bbb"}]},
      ]

    markdown_example 225, %q(
    aaa
bbb), [
        {code_block: {ln: "aaa"}},
        {p: {ln: "bbb"}},
      ], strip: false # deletes significant indentation for the block

    it "parses example 226" do
      pending "hard break (inline)"
      expect(subject.parse_with_debug(%q(
aaa     
bbb     ))).to eq([
        {p: {ln: "aaa"}},
        {br: "     "},
        {p: {ln: "bbb"}},
      ])
    end

  end
end
