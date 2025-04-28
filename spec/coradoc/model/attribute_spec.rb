require "spec_helper"

RSpec.describe Coradoc::Model::Attribute do
  describe ".initialize" do
    it "initializes with key and value" do
      attr = described_class.new(
        key: "format",
        value: "pdf"
      )

      expect(attr.key).to eq("format")
      expect(attr.value).to eq("pdf")
    end

    it "accepts array values" do
      attr = described_class.new(
        key: "formats",
        value: ["pdf", "html", "docx"]
      )

      expect(attr.key).to eq("formats")
      expect(attr.value).to eq(["pdf", "html", "docx"])
    end

    it "handles empty value" do
      attr = described_class.new(key: "empty")
      expect(attr.key).to eq("empty")
      expect(attr.value).to be_nil
    end
  end

  describe "#build_values" do
    let(:instance) { described_class.new }

    it "splits comma-separated values" do
      result = instance.send(:build_values, "pdf,html,docx")
      expect(result).to eq(["pdf", "html", "docx"])
    end

    it "strips whitespace from values" do
      result = instance.send(:build_values, "pdf , html , docx")
      expect(result).to eq(["pdf", "html", "docx"])
    end

    it "returns single value without array for single item" do
      result = instance.send(:build_values, "pdf")
      expect(result).to eq("pdf")
    end

    it "returns single value without array for single item with spaces" do
      result = instance.send(:build_values, " pdf ")
      expect(result).to eq("pdf")
    end

    it "handles empty string" do
      result = instance.send(:build_values, "")
      expect(result).to eq("")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end
end
