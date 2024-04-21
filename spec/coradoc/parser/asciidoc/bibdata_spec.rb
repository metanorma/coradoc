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
        :mn-output-extensions: xml,html,doc,html_alt
        :title-main-fr: Spécification et méthodes d'essai
      DOC

      ast = Asciidoc::BibdataTester.parse(bibdata).first

      expect(ast[:bibdata].count).to eq(7)
      expect(ast[:bibdata][0][:key]).to eq("published")
      expect(ast[:bibdata][0][:value]).to eq("'2023-03-08T09:51:08+08:00'")

      expect(ast[:bibdata][2][:key]).to eq("version")
      expect(ast[:bibdata][2][:value]).to eq("'1.0'")

      expect(ast[:bibdata][4][:key]).to eq("remarks")
      expect(ast[:bibdata][4][:value]).to eq("OSCAL from ISO27002:2022")

      expect(ast[:bibdata][5][:key]).to eq("mn-output-extensions")
      expect(ast[:bibdata][5][:value]).to eq("xml,html,doc,html_alt")

      expect(ast[:bibdata][6][:key]).to eq("title-main-fr")
      expect(ast[:bibdata][6][:value]).to eq("Spécification et méthodes d'essai")
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
