require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::InlineParser do
  describe "characters" do
    markdown_example 12, "\0owo &uwu; &#x1F3F3;&#Xfe0f;&#8205;&#x26A7;&#65039; &#xd83f; &larr; &rarr;", [], strip: false
    markdown_example 12, %q(\!\"\#\$\%\&\'\\\(\\\)\*\+\,\-\.\/\:\;\<\=\>\?\@\[\\\]\^\_\`\{\|\}\~), [
        {p: {ln: "bbb"}},
      ], strip: false
  end
end
