require "spec_helper"

RSpec.describe Coradoc::Model::Bibliography do
  describe ".initialize" do
    it "initializes with basic attributes" do
      bib = described_class.new(
        id: "bib-1",
        title: "References"
      )

      expect(bib.id).to eq("bib-1")
      expect(bib.title).to eq("References")
      expect(bib.entries).to eq([])
    end

    it "accepts bibliography entries" do
      entries = [
        instance_double(Coradoc::Model::BibliographyEntry),
        instance_double(Coradoc::Model::BibliographyEntry)
      ]

      bib = described_class.new(
        title: "References",
        entries: entries
      )

      expect(bib.entries).to eq(entries)
    end
  end

  describe "#to_asciidoc" do
    let(:title) { "References" }
    let(:entries) do
      [
        instance_double(Coradoc::Model::BibliographyEntry, to_asciidoc: "* [[[ref1]]] First reference"),
        instance_double(Coradoc::Model::BibliographyEntry, to_asciidoc: "* [[[ref2]]] Second reference")
      ]
    end

    it "generates complete bibliography" do
      bib = described_class.new(
        title: title,
        entries: entries
      )

      expected_output = "\n[bibliography]== References\n\n* [[[ref1]]] First reference\n* [[[ref2]]] Second reference\n"
      expect(bib.to_asciidoc).to eq(expected_output)
    end

    it "includes anchor when present" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[bibliography]]"
      )

      bib = described_class.new(
        title: title,
        entries: entries
      )
      allow(bib).to receive(:anchor).and_return(anchor)
      allow(bib).to receive(:gen_anchor).and_return("[[bibliography]]\n")

      expected_output = "[[bibliography]]\n[bibliography]== References\n\n* [[[ref1]]] First reference\n* [[[ref2]]] Second reference\n"
      expect(bib.to_asciidoc).to eq(expected_output)
    end

    it "handles bibliography without entries" do
      bib = described_class.new(title: title)

      expected_output = "\n[bibliography]== References\n\n"
      expect(bib.to_asciidoc).to eq(expected_output)
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
