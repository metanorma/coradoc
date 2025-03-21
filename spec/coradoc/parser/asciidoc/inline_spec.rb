require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Inline" do
  describe ".parse" do
    it "parses various inline text formattings" do
      parser = Asciidoc::InlineTextFormattingTester

      ast = parser.parse("*bold*")
      expect(ast).to eq([{ bold_constrained: [{ text: "bold" }] }])
      ast = parser.parse("**bold**")
      expect(ast).to eq([{ bold_unconstrained: [{ text: "bold" }] }])
      parser.parse("line with *bold*")
      [{ text: [
        "line with ",
        { bold_constrained: [{ text: "bold" }] },
      ] }]
      # expect(ast).to eq(exp)
      parser.parse("line with**bold**")

      parser.parse("line with *bold* #highlight#")

      parser.parse("line with**bold** ##highlight##")
    end
  end
end

module Asciidoc
  class InlineTextFormattingTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) { (text_formatted | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
