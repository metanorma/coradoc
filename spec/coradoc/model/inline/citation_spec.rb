require "spec_helper"

RSpec.describe Coradoc::Model::Inline::Citation do
  let(:cross_reference) { instance_double(Coradoc::Model::Inline::CrossReference) }

  describe ".initialize" do
    it "initializes with cross reference and comment" do
      citation = described_class.new(
        cross_reference: cross_reference,
        comment: "See section 1.2"
      )

      expect(citation.cross_reference).to eq(cross_reference)
      expect(citation.comment).to eq("See section 1.2")
    end

    it "accepts partial attributes" do
      citation = described_class.new(cross_reference: cross_reference)

      expect(citation.cross_reference).to eq(cross_reference)
      expect(citation.comment).to be_nil
    end

    it "initializes with no attributes" do
      citation = described_class.new

      expect(citation.cross_reference).to be_nil
      expect(citation.comment).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with cross reference only" do
      it "generates citation with cross reference" do
        allow(cross_reference).to receive(:to_asciidoc).and_return("<<section-1>>")

        citation = described_class.new(cross_reference: cross_reference)

        expected_output = "[.source]\n<<section-1>>\n"
        expect(citation.to_asciidoc).to eq(expected_output)
      end
    end

    context "with comment only" do
      it "generates citation with comment" do
        citation = described_class.new(comment: "See section 1.2")

        expected_output = "[.source]\nSee section 1.2"
        expect(citation.to_asciidoc).to eq(expected_output)
      end

      it "processes comment through Generator" do
        comment = "See section 1.2"
        citation = described_class.new(comment: comment)

        expect(Coradoc::Generator).to receive(:gen_adoc).with(comment)
        citation.to_asciidoc
      end
    end

    context "with both cross reference and comment" do
      it "generates complete citation" do
        allow(cross_reference).to receive(:to_asciidoc).and_return("<<section-1>>")

        citation = described_class.new(
          cross_reference: cross_reference,
          comment: "See section 1.2"
        )

        expected_output = "[.source]\n<<section-1>>See section 1.2"
        expect(citation.to_asciidoc).to eq(expected_output)
      end
    end

    it "handles empty citation" do
      citation = described_class.new
      expect(citation.to_asciidoc).to eq("[.source]\n")
    end

    it "handles multiline comments" do
      citation = described_class.new(
        comment: "First line\nSecond line"
      )

      expected_output = "[.source]\nFirst line\nSecond line"
      expect(citation.to_asciidoc).to eq(expected_output)
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "asciidoc mapping" do
    it "maps all attributes correctly" do
      mapping = described_class.asciidoc_mapping.mappings
      mapped_attributes = mapping.map { |m| m.instance_variable_get(:@to) }

      expect(mapped_attributes).to include(:cross_reference, :comment)
    end
  end
end
