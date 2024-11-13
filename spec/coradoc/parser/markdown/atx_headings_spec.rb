require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown do
  describe "ATX headings" do
    it "parses example 62" do
      expect(subject.parse_with_debug(%q(
# foo
## foo
### foo
#### foo
##### foo
###### foo
      ))).to eq([
        {heading: "#", text: "foo"},
        {heading: "##", text: "foo"},
        {heading: "###", text: "foo"},
        {heading: "####", text: "foo"},
        {heading: "#####", text: "foo"},
        {heading: "######", text: "foo"},
      ])
    end

    it "parses example 63" do
      expect(subject.parse_with_debug(%q(
####### foo
      ))).to eq([
        {p: {ln: "####### foo"}}
      ])
    end

    it "parses example 64" do
      expect(subject.parse_with_debug(%q(
#5 bolt

#hashtag
      ))).to eq([
        {p: {ln: "#5 bolt"}},
        {p: {ln: "#hashtag"}},
      ])
    end

    pending "parses example 65"
    pending "parses example 66"

    it "parses example 67" do
      expect(subject.parse_with_debug(%q(
#                  foo                     
      ))).to eq([
        {heading: "#", text: "foo"},
      ])
    end

    it "parses example 68" do
      expect(subject.parse_with_debug(%q(
 ### foo
  ## foo
   # foo
      ))).to eq([
        {heading: "###", text: "foo"},
        {heading: "##", text: "foo"},
        {heading: "#", text: "foo"},
      ])
    end

    it "parses example 69" do
      expect(subject.parse_with_debug(%q(
    # foo
      ))).to eq([
        {code_block: [{ln: "# foo"}, {ln: "  "}]}
      ])
    end

    it "parses example 70" do
      expect(subject.parse_with_debug(%q(
foo
    # bar
      ))).to eq([
        {p: [{ln: "foo"}, {ln: "    # bar"}]}
      ])
    end

    it "parses example 71" do
      expect(subject.parse_with_debug(%q(
## foo ##
  ###   bar    ###
      ))).to eq([
        {heading: "##", text: "foo"},
        {heading: "###", text: "bar"},
      ])
    end

    it "parses example 72" do
      expect(subject.parse_with_debug(%q(
# foo ##################################
##### foo ##
      ))).to eq([
        {heading: "#", text: "foo"},
        {heading: "#####", text: "foo"},
      ])
    end

    it "parses example 73" do
      expect(subject.parse_with_debug(%q(
### foo ###     
      ))).to eq([
        {heading: "###", text: "foo"},
      ])
    end

    it "parses example 74" do
      expect(subject.parse_with_debug(%q(
### foo ### b
      ))).to eq([
        {heading: "###", text: "foo ### b"},
      ])
    end

    it "parses example 75" do
      expect(subject.parse_with_debug(%q(
# foo#
      ))).to eq([
        {heading: "#", text: "foo#"},
      ])
    end

    it "parses example 76" do
      pending "escapes"
      expect(subject.parse_with_debug(%q(
### foo \###
## foo #\##
# foo \#
      ))).to eq([
        {heading: "###", text: "foo ###"},
        {heading: "##", text: "foo ###"},
        {heading: "#", text: "foo #"},
      ])
    end

    it "parses example 77" do
      expect(subject.parse_with_debug(%q(
****
## foo
****
      ))).to eq([
        {hr: true},
        {heading: "##", text: "foo"},
        {hr: true},
      ])
    end

    it "parses example 78" do
      expect(subject.parse_with_debug(%q(
Foo bar
# baz
Bar foo
      ))).to eq([
        {p: {ln: "Foo bar"}},
        {heading: "#", text: "baz"},
        {p: {ln: "Bar foo"}},
      ])
    end

    it "parses example 79" do
      expect(subject.parse_with_debug(%q(
## 
#
### ###
      ))).to eq([
        {heading: "##"},
        {heading: "#"},
        {heading: "###"},
      ])
    end

  end
end

