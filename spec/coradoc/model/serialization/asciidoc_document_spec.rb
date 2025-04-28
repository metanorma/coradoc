require "spec_helper"

RSpec.describe Coradoc::Model::Serialization::AsciidocDocument do
  let(:sections) { [double("Section1", to_asciidoc: "Section 1"), double("Section2", to_asciidoc: "Section 2")] }
  let(:document) { described_class.new(sections) }

  describe ".initialize" do
    it "initializes with empty sections by default" do
      doc = described_class.new
      expect(doc.sections).to be_empty
    end

    it "initializes with provided sections" do
      expect(document.sections).to eq(sections)
    end
  end

  describe ".parse" do
    let(:asciidoc_data) { "Some asciidoc content" }
    let(:parsed_data) { { document: sections } }
    let(:parser) { instance_double(Coradoc::Parser::Base, parse: parsed_data) }

    before do
      allow(Coradoc::Parser::Base).to receive(:new).with(asciidoc_data).and_return(parser)
    end

    it "parses asciidoc data into document sections" do
      doc = described_class.parse(asciidoc_data)
      expect(doc.sections).to eq(sections)
    end
  end

  describe "#to_asciidoc" do
    it "joins sections with double newlines" do
      expect(document.to_asciidoc).to eq("Section 1\n\nSection 2")
    end

    it "handles empty sections array" do
      doc = described_class.new([])
      expect(doc.to_asciidoc).to eq("")
    end
  end

  describe "array-like access" do
    it "supports [] access" do
      expect(document[0]).to eq(sections[0])
      expect(document[1]).to eq(sections[1])
    end

    it "supports []= assignment" do
      new_section = double("Section3", to_asciidoc: "Section 3")
      document[1] = new_section
      expect(document[1]).to eq(new_section)
    end
  end

  describe "#to_h" do
    it "returns the sections array" do
      expect(document.to_h).to eq(sections)
    end
  end

  describe "#map" do
    it "maps over sections" do
      result = document.map { |section| section.to_asciidoc.upcase }
      expect(result).to eq(["SECTION 1", "SECTION 2"])
    end
  end
end
