require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Admonition" do
  describe ".parse" do
    it "parses one line admonition" do
      parser = Asciidoc::AdmonitionTester

      ast = parser.parse("NOTE: some text\n")
      exp = [{ admonition_type: "NOTE",
               content: [{ text: "some text",
                           line_break: "\n" }] }]
      expect(ast).to eq(exp)
    end

    it "parses multi line admonition" do
      parser = Asciidoc::AdmonitionTester

      ast = parser.parse("NOTE: some text\ncontinued\n")
      exp = [{ admonition_type: "NOTE",
               content: [{ text: "some text", line_break: "\n" },
                         { text: "continued",
                           line_break: "\n" }] }]

      expect(ast).to eq(exp)
    end
  end
end

module Asciidoc
  class AdmonitionTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) do
      (admonition_line | any.as(:unparsed)).repeat(1)
    end
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
