# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocDocumentEntry do
  describe ".initialize" do
    it "initializes with required attributes" do
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: { "id" => "section-1" }
      )

      expect(entry.entry_type).to eq("section")
      expect(entry.content).to eq("Section content")
      expect(entry.attributes).to eq({ "id" => "section-1" })
      expect(entry.mapping).to be_nil
    end

    it "accepts optional mapping parameter" do
      mapping = double("Mapping")
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: {},
        mapping: mapping
      )

      expect(entry.mapping).to eq(mapping)
    end
  end

  describe ".parse" do
    it "creates a new entry with downcased type" do
      entry = described_class.parse(
        "SECTION",
        "Section content",
        { "id" => "section-1" },
        nil
      )

      expect(entry.entry_type).to eq("section")
      expect(entry.content).to eq("Section content")
      expect(entry.attributes).to eq({ "id" => "section-1" })
    end
  end

  describe "#to_adoc" do
    it "generates AsciiDoc output with attributes" do
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: {
          "id" => "section-1",
          "role" => "important"
        }
      )

      expected_output = '[id="section-1",role="important"]
section::Section content'

      expect(entry.to_adoc).to eq(expected_output)
    end

    it "generates AsciiDoc output without attributes" do
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: {}
      )

      expect(entry.to_adoc).to eq("section::Section content")
    end

    it "handles single attribute" do
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: { "id" => "section-1" }
      )

      expect(entry.to_adoc).to eq('[id="section-1"]
section::Section content')
    end

    it "handles attributes with special characters" do
      entry = described_class.new(
        entry_type: "section",
        content: "Section content",
        attributes: { "data-test" => "value with spaces" }
      )

      expect(entry.to_adoc).to eq('[data-test="value with spaces"]
section::Section content')
    end
  end
end
