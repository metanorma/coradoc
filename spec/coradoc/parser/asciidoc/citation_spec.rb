require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Citatione" do
  describe ".parse" do
    it "parses various inline text formattings" do
      parser = Asciidoc::CitationTester


      ast = parser.parse("[.source]\nsome reference\n")
      expect(ast).to eq([{:citation=>{:comment=>[{:text=>"some reference", :line_break=>"\n"}]}}])

      ast = parser.parse("[.source]\n<<xref_anchor>>\n")
      expect(ast).to eq([{:citation=>{:cross_reference=>[{:href_arg=>"xref_anchor"}]}}])


      ast = parser.parse("[.source]\n<<xref_anchor,display text>>\n")
      expect(ast).to eq([{:citation=>{:cross_reference=>[{:href_arg=>"xref_anchor"}, {:text=>"display text"}]}}])


      ast = parser.parse("[.source]\n<<xref_anchor,section=1>>\n")
      expect(ast).to eq([{:citation=>{:cross_reference=>[{:href_arg=>"xref_anchor"}, {:key=>"section", :delimiter=>"=", :value=>"1"}]}}])

      ast = parser.parse("[.source]\n<<xref_anchor>>some reference\n")
      expect(ast).to eq([{:citation=>{:cross_reference=>[{:href_arg=>"xref_anchor"}], :comment=>[{:text=>"some reference", :line_break=>"\n"}]}}])

      ast = parser.parse("[.source]\n<<xref_anchor>>some reference\nsecond line\n")
      expect(ast).to eq([{:citation=>{:cross_reference=>[{:href_arg=>"xref_anchor"}], :comment=>[{:text=>"some reference", :line_break=>"\n"}, {:text=>"second line", :line_break=>"\n"}]}}])

    end
  end
end


module Asciidoc
  class CitationTester < Parslet::Parser
    include Coradoc::Parser::Asciidoc::Base

    rule(:document) { (citation | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end