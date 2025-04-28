require "spec_helper"

RSpec.describe Coradoc::Model::Term do
  describe ".initialize" do
    it "initializes with all attributes" do
      term = described_class.new(
        term: "example",
        type: "stem",
        lang: "fr",
        line_break: "\n"
      )

      expect(term.term).to eq("example")
      expect(term.type).to eq("stem")
      expect(term.lang).to eq("fr")
      expect(term.line_break).to eq("\n")
    end

    it "uses default values" do
      term = described_class.new

      expect(term.term).to be_nil
      expect(term.type).to be_nil
      expect(term.lang).to eq("en")
      expect(term.line_break).to eq("")
    end

    it "accepts partial attributes" do
      term = described_class.new(term: "example", type: "stem")

      expect(term.term).to eq("example")
      expect(term.type).to eq("stem")
      expect(term.lang).to eq("en")
      expect(term.line_break).to eq("")
    end
  end

  describe "#to_asciidoc" do
    context "with English language (default)" do
      it "formats term with type-first syntax" do
        term = described_class.new(
          term: "example",
          type: "stem"
        )

        expect(term.to_asciidoc).to eq("stem:[example]")
      end

      it "includes line break when specified" do
        term = described_class.new(
          term: "example",
          type: "stem",
          line_break: "\n"
        )

        expect(term.to_asciidoc).to eq("stem:[example]\n")
      end
    end

    context "with non-English language" do
      it "formats term with hash notation" do
        term = described_class.new(
          term: "exemple",
          type: "stem",
          lang: "fr"
        )

        expect(term.to_asciidoc).to eq("[stem]#exemple#")
      end

      it "includes line break when specified" do
        term = described_class.new(
          term: "exemple",
          type: "stem",
          lang: "fr",
          line_break: "\n"
        )

        expect(term.to_asciidoc).to eq("[stem]#exemple#\n")
      end
    end

    it "handles empty term" do
      term = described_class.new(type: "stem")
      expect(term.to_asciidoc).to eq("stem:[]")
    end

    it "handles empty type" do
      term = described_class.new(term: "example")
      expect(term.to_asciidoc).to eq(":[example]")
    end

    it "handles nil values" do
      term = described_class.new
      expect(term.to_asciidoc).to eq(":[nil]")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "common use cases" do
    it "works for mathematical terms" do
      term = described_class.new(
        term: "x^2",
        type: "stem"
      )
      expect(term.to_asciidoc).to eq("stem:[x^2]")
    end

    it "works for chemical formulas" do
      term = described_class.new(
        term: "H2O",
        type: "chem"
      )
      expect(term.to_asciidoc).to eq("chem:[H2O]")
    end

    it "works for foreign language terms" do
      term = described_class.new(
        term: "raison d'être",
        type: "foreign",
        lang: "fr"
      )
      expect(term.to_asciidoc).to eq("[foreign]#raison d'être#")
    end
  end
end
