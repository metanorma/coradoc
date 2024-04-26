require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::DocumentAttributes" do
  describe ".parse" do
    it "parses document_attributes attributes" do
      document_attributes = <<~DOC
        :published: '2023-03-08T09:51:08+08:00'
        :last-modified: '2023-03-08T09:51:08+08:00'
        :version: '1.0'
        :oscal-version: 1.0.0
        :remarks: OSCAL from ISO27002:2022
        :mn-output-extensions: xml,html,doc,html_alt
        :title-main-fr: Spécification et méthodes d'essai
      DOC

      ast = Asciidoc::DocumentAttributesTester.parse(document_attributes).first

      expect(ast[:document_attributes].count).to eq(7)
      expect(ast[:document_attributes][0][:key]).to eq("published")
      expect(ast[:document_attributes][0][:value]).to eq("'2023-03-08T09:51:08+08:00'")

      expect(ast[:document_attributes][2][:key]).to eq("version")
      expect(ast[:document_attributes][2][:value]).to eq("'1.0'")

      expect(ast[:document_attributes][4][:key]).to eq("remarks")
      expect(ast[:document_attributes][4][:value]).to eq("OSCAL from ISO27002:2022")

      expect(ast[:document_attributes][5][:key]).to eq("mn-output-extensions")
      expect(ast[:document_attributes][5][:value]).to eq("xml,html,doc,html_alt")

      expect(ast[:document_attributes][6][:key]).to eq("title-main-fr")
      expect(ast[:document_attributes][6][:value]).to eq("Spécification et méthodes d'essai")
    end

  end

  module Asciidoc
    class DocumentAttributesTester < Parslet::Parser
      include Coradoc::Parser::Asciidoc::DocumentAttributes

      rule(:document) { (document_attributess.as(:document_attributes) | any.as(:unparsed)).repeat(1) }
      root :document

      def self.parse(text)
        new.parse_with_debug(text)
      end
    end
  end
end
