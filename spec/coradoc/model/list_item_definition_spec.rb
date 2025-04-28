require "spec_helper"

RSpec.describe Coradoc::Model::ListItemDefinition do
  describe ".initialize" do
    it "initializes with basic attributes" do
      term = instance_double(Coradoc::Model::Term)
      item = described_class.new(
        id: "def-1",
        contents: "Definition content",
        terms: [term]
      )

      expect(item.id).to eq("def-1")
      expect(item.contents).to eq("Definition content")
      expect(item.terms).to eq([term])
    end

    it "initializes with empty collections" do
      item = described_class.new
      expect(item.terms).to eq([])
      expect(item.contents).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content.is_a?(Array) ? content.first : content }
    end

    context "with single term" do
      let(:term) { instance_double(Coradoc::Model::Term, to_asciidoc: "term") }

      it "generates definition with single term" do
        item = described_class.new(
          contents: "Definition",
          terms: [term]
        )

        expect(item.to_asciidoc(":")).to eq("term: Definition\n")
      end

      it "includes anchor when present" do
        anchor = instance_double(Coradoc::Model::Inline::Anchor,
          to_asciidoc: "[[def-1]]"
        )

        item = described_class.new(
          contents: "Definition",
          terms: [term]
        )
        allow(item).to receive(:anchor).and_return(anchor)

        expect(item.to_asciidoc(":")).to eq("[[def-1]]term: Definition\n")
      end
    end

    context "with multiple terms" do
      let(:term1) { instance_double(Coradoc::Model::Term, to_asciidoc: "term1") }
      let(:term2) { instance_double(Coradoc::Model::Term, to_asciidoc: "term2") }

      it "generates definition with multiple terms" do
        item = described_class.new(
          contents: "Definition",
          terms: [term1, term2]
        )

        expected_output = "term1:\nterm2:\nDefinition\n"
        expect(item.to_asciidoc(":")).to eq(expected_output)
      end
    end

    context "with different delimiters" do
      let(:term) { instance_double(Coradoc::Model::Term, to_asciidoc: "term") }

      it "uses double colon delimiter" do
        item = described_class.new(
          contents: "Definition",
          terms: [term]
        )

        expect(item.to_asciidoc("::")).to eq("term:: Definition\n")
      end

      it "uses triple colon delimiter" do
        item = described_class.new(
          contents: "Definition",
          terms: [term]
        )

        expect(item.to_asciidoc(":::")).to eq("term::: Definition\n")
      end
    end

    it "handles empty contents" do
      term = instance_double(Coradoc::Model::Term, to_asciidoc: "term")
      item = described_class.new(terms: [term])

      expect(item.to_asciidoc(":")).to eq("term: \n")
    end
  end

  describe "inheritance and includes" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end


end
