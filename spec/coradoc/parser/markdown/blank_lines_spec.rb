require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::BlockParser do
  describe "blank lines" do
    markdown_example 227, %q(
  

aaa
  

# aaa

  ), [
    {p: {ln: "aaa"}},
    {heading: "#", text: "aaa"},
    ]
  end
end
