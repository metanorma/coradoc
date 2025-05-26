require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Tag" do
  describe ".parse" do
    it "parses tags" do
      parser = Asciidoc::TagTester

      ast = parser.parse("// tag::name[]\n")
      expect(ast).to eq(
        [{ tag: { prefix: "tag", name: "name",
        attribute_list: { attribute_array: [] }, line_break: "\n" } }],
      )

      ast = parser.parse("// end::name[]\n")
      expect(ast).to eq(
        [{ tag: { prefix: "end", name: "name",
        attribute_list: { attribute_array: [] }, line_break: "\n" } }],
      )

      ast = parser.parse("// tag::name[]")
      expect(ast).to eq(
        [{ tag: { prefix: "tag", name: "name",
        attribute_list: { attribute_array: [] }, line_break: nil } }],
      )
    end
  end
end

module Asciidoc
  class TagTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) do
      (tag | any.as(:unparsed)).repeat(1)
    end
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
