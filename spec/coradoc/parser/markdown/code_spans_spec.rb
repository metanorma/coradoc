require "spec_helper"

RSpec.describe Coradoc::Parser::Markdown::InlineParser do
  describe "inline code spans" do
    markdown_example 328, "`foo`", [{code: "foo"}], strip: false
    markdown_example 329, "`` foo ` bar ``", [{code: "foo ` bar"}], strip: false
    markdown_example 330, "` `` `", [{code: "``"}], strip: false
    markdown_example 331, "`  ``  `", [{code: " `` "}], strip: false
    markdown_example 332, "` a`", [{code: " a"}], strip: false
    markdown_example 333, "` b `", [{code: " b "}], strip: false
    markdown_example 334, %q(` `
`  `), [{code: " "}, {text: "\n"}, {code: "  "}], strip: false
    markdown_example 335, %q(``
foo
bar  
baz
``), [{code: "foo bar   baz"}], strip: false
    markdown_example 336, %q(``
foo 
``), [{code: "foo "}], strip: false
    markdown_example 337, %q(`foo   bar 
baz`), [{code: "foo   bar  baz"}], strip: false
    markdown_example 338, '`foo\`bar`', [{code: "foo\\"}, {text: "bar`"}], strip: false
    markdown_example 339, "``foo`bar``", [{code: "foo`bar"}], strip: false
    markdown_example 340, "` foo `` bar `", [{code: "foo `` bar"}], strip: false
    markdown_example 341, "*foo`*`", [{text: "*"}, {text: "foo"}, {code: "*"}], strip: false
    markdown_example 342, "[not a `link](/foo`)", [{text: "[not a "}, {code: "link](/foo"}, {text: ")"}], strip: false
    # markdown_example 343, %q(`<a href="`">`), [{code: "&lt;a href=&quot;"}, {text: "&quot;&gt;`"}], strip: false (pending: html escape)
    # 344 (pending: html)
    # 345 (pending: html escape)
    # 346 (pending: autolink)
    markdown_example 347, "```foo``", [{text: "```foo``"}], strip: false
    markdown_example 348, "`foo", [{text: "`foo"}], strip: false
    markdown_example 349, "`foo``bar``", [{text: "`foo"}, {code: "bar"}], strip: false
  end
end
