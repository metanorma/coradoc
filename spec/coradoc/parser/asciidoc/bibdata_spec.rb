require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::Bibdata" do
  describe ".parse" do
    it "parses bibdata attributes" do
      bibdata = <<~DOC
        :published: '2023-03-08T09:51:08+08:00'
        :last-modified: '2023-03-08T09:51:08+08:00'
        :version: '1.0'
        :oscal-version: 1.0.0
        :remarks: OSCAL from ISO27002:2022
      DOC

      ast = Asciidoc::BibdataTester.parse(bibdata)

      expect(ast.first[:bibdata].count).to eq(5)
      expect(ast.first[:bibdata][0][:key]).to eq("published")
      expect(ast.first[:bibdata][0][:value]).to eq("'2023-03-08T09:51:08+08:00'")

      expect(ast.first[:bibdata][2][:key]).to eq("version")
      expect(ast.first[:bibdata][2][:value]).to eq("'1.0'")

      expect(ast.first[:bibdata][4][:key]).to eq("remarks")
      expect(ast.first[:bibdata][4][:value]).to eq("OSCAL from ISO27002:2022")
    end

  end

  module Asciidoc
    class BibdataTester < Parslet::Parser
      include Coradoc::Parser::Asciidoc::Bibdata

      rule(:document) { (bibdatas.as(:bibdata) | any.as(:unparsed)).repeat(1) }
      root :document

      def self.parse(text)
        new.parse_with_debug(text)
      end
    end
  end
end
