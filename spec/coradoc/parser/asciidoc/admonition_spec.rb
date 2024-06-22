require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Admonition" do
  describe ".parse" do
    it "parses admonitions" do
      parser = Asciidoc::AdmonitionTester

      ast = parser.parse("NOTE: some text\n")
      exp = [{:admonition_type=>"NOTE", 
        :text => "some text",
        :line_break => "\n"}]
      expect(ast).to eq(exp)

    end
  end
end


module Asciidoc
  class AdmonitionTester < Parslet::Parser
    include Coradoc::Parser::Asciidoc::Base

    rule(:document) { (admonition_line | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
