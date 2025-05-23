# frozen_string_literal: true

RSpec.describe Coradoc::Model::BibliographyEntry do
  describe ".initialize" do
    it "initializes with all attributes" do
      entry = described_class.new(
        anchor_name: "ref1",
        document_id: "doc1",
        ref_text: "Reference text",
        line_break: "\n"
      )

      expect(entry.anchor_name).to eq("ref1")
      expect(entry.document_id).to eq("doc1")
      expect(entry.ref_text).to eq("Reference text")
      expect(entry.line_break).to eq("\n")
    end

    it "uses default values when not provided" do
      entry = described_class.new

      expect(entry.anchor_name).to be_nil
      expect(entry.document_id).to be_nil
      expect(entry.ref_text).to be_nil
      expect(entry.line_break).to eq("")
    end

    it "accepts partial attributes" do
      entry = described_class.new(
        anchor_name: "ref1",
        ref_text: "Reference text"
      )

      expect(entry.anchor_name).to eq("ref1")
      expect(entry.ref_text).to eq("Reference text")
      expect(entry.document_id).to be_nil
      expect(entry.line_break).to eq("")
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |text| text }
    end

    it "generates complete bibliography entry" do
      entry = described_class.new(
        anchor_name: "ref1",
        document_id: "doc1",
        ref_text: "Reference text",
        line_break: "\n"
      )

      expect(entry.to_asciidoc).to eq("* [[[ref1,doc1]]]Reference text\n")
    end

    it "generates entry without document_id" do
      entry = described_class.new(
        anchor_name: "ref1",
        ref_text: "Reference text",
        line_break: "\n"
      )

      expect(entry.to_asciidoc).to eq("* [[[ref1]]]Reference text\n")
    end

    it "generates entry without ref_text" do
      entry = described_class.new(
        anchor_name: "ref1",
        document_id: "doc1",
        line_break: "\n"
      )

      expect(entry.to_asciidoc).to eq("* [[[ref1,doc1]]]\n")
    end

    it "generates minimal entry" do
      entry = described_class.new(
        anchor_name: "ref1"
      )

      expect(entry.to_asciidoc).to eq("* [[[ref1]]]")
    end

    it "processes ref_text through Generator.gen_adoc" do
      entry = described_class.new(
        anchor_name: "ref1",
        ref_text: "Reference text"
      )

      expect(Coradoc::Generator).to receive(:gen_adoc).with("Reference text")
      entry.to_asciidoc
    end

    it "handles nil ref_text" do
      entry = described_class.new(
        anchor_name: "ref1"
      )

      expect(Coradoc::Generator).not_to receive(:gen_adoc)
      entry.to_asciidoc
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
