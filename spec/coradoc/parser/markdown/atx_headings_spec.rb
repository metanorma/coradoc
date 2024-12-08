require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "ATX headings" do
    markdown_example 62, %q(
# foo
## foo
### foo
#### foo
##### foo
###### foo
), [
  {heading: "#", text: "foo"},
  {heading: "##", text: "foo"},
  {heading: "###", text: "foo"},
  {heading: "####", text: "foo"},
  {heading: "#####", text: "foo"},
  {heading: "######", text: "foo"},
]

    markdown_example 63, %q(
####### foo
), [
  {p: {ln: "####### foo"}}
]

    markdown_example 64, %q(
#5 bolt

#hashtag
), [
  {p: {ln: "#5 bolt"}},
  {p: {ln: "#hashtag"}},
]

    pending "parses example 65"
    pending "parses example 66"

    markdown_example 67, %q(
#                  foo                     
), [
  {heading: "#", text: "foo"},
]

    markdown_example 68, %q(
 ### foo
  ## foo
   # foo
), [
  {heading: "###", text: "foo"},
  {heading: "##", text: "foo"},
  {heading: "#", text: "foo"},
]

    markdown_example 69, %q(
    # foo
), [
  {code_block: {ln: "# foo"}}
], strip: false # deletes significant indentation for the block

    markdown_example 70, %q(
foo
    # bar
), [
  {p: [{ln: "foo"}, {ln: "# bar"}]}
]

    markdown_example 71, %q(
## foo ##
  ###   bar    ###
), [
  {heading: "##", text: "foo"},
  {heading: "###", text: "bar"},
]

    markdown_example 72, %q(
# foo ##################################
##### foo ##
), [
  {heading: "#", text: "foo"},
  {heading: "#####", text: "foo"},
]

    markdown_example 73, %q(
### foo ###     
), [
  {heading: "###", text: "foo"},
]

    markdown_example 74, %q(
### foo ### b
), [
  {heading: "###", text: "foo ### b"},
]

    markdown_example 75, %q(
# foo#
), [
  {heading: "#", text: "foo#"},
]

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

    markdown_example 77, %q(
****
## foo
****
), [
  {hr: true},
  {heading: "##", text: "foo"},
  {hr: true},
]

    markdown_example 78, %q(
Foo bar
# baz
Bar foo
), [
  {p: {ln: "Foo bar"}},
  {heading: "#", text: "baz"},
  {p: {ln: "Bar foo"}},
]

    markdown_example 79, %q(
## 
#
### ###
), [
  {heading: "##"},
  {heading: "#"},
  {heading: "###"},
]

  end
end

