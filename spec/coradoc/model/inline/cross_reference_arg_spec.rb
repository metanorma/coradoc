require "spec_helper"

RSpec.describe Coradoc::Model::Inline::CrossReferenceArg do
  describe ".initialize" do
    it "initializes with all attributes" do
      arg = described_class.new(
        key: "page",
        delimiter: ":",
        value: "5"
      )

      expect(arg.key).to eq("page")
      expect(arg.delimiter).to eq(":")
      expect(arg.value).to eq("5")
    end

    it "accepts partial attributes" do
      arg = described_class.new(key: "page")

      expect(arg.key).to eq("page")
      expect(arg.delimiter).to be_nil
      expect(arg.value).to be_nil
    end

    it "initializes with no attributes" do
      arg = described_class.new

      expect(arg.key).to be_nil
      expect(arg.delimiter).to be_nil
      expect(arg.value).to be_nil
    end
  end

  describe "#to_asciidoc" do
    context "with all attributes" do
      it "joins all components" do
        arg = described_class.new(
          key: "page",
          delimiter: ":",
          value: "5"
        )

        expect(arg.to_asciidoc).to eq("page:5")
      end

      it "preserves whitespace in values" do
        arg = described_class.new(
          key: "text",
          delimiter: ":",
          value: "Section 1.2"
        )

        expect(arg.to_asciidoc).to eq("text:Section 1.2")
      end
    end

    context "with partial attributes" do
      it "handles missing delimiter" do
        arg = described_class.new(
          key: "page",
          value: "5"
        )

        expect(arg.to_asciidoc).to eq("page5")
      end

      it "handles missing value" do
        arg = described_class.new(
          key: "page",
          delimiter: ":"
        )

        expect(arg.to_asciidoc).to eq("page:")
      end

      it "handles key only" do
        arg = described_class.new(key: "page")
        expect(arg.to_asciidoc).to eq("page")
      end
    end

    it "handles nil values" do
      arg = described_class.new
      expect(arg.to_asciidoc).to eq("")
    end

    it "preserves special characters" do
      arg = described_class.new(
        key: "ref",
        delimiter: ":",
        value: "section-1.2_3"
      )

      expect(arg.to_asciidoc).to eq("ref:section-1.2_3")
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

      expect(mapped_attributes).to include(:key, :delimiter, :value)
    end
  end

  describe "usage examples" do
    it "works for page references" do
      arg = described_class.new(
        key: "page",
        delimiter: ":",
        value: "5"
      )
      expect(arg.to_asciidoc).to eq("page:5")
    end

    it "works for section references" do
      arg = described_class.new(
        key: "text",
        delimiter: ":",
        value: "Section Title"
      )
      expect(arg.to_asciidoc).to eq("text:Section Title")
    end
  end
end
