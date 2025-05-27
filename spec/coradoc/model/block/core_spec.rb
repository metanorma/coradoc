# frozen_string_literal: true

RSpec.describe Coradoc::Model::Block::Core do
  let(:attributes) { instance_double(Coradoc::Model::AttributeList) }

  describe ".initialize" do
    it "initializes with all attributes" do
      block = described_class.new(
        id: "block-1",
        title: "Block Title",
        attributes: attributes,
        lines: ["Line 1", "Line 2"],
        delimiter: "----",
        delimiter_char: "-",
        delimiter_len: 4,
        lang: "ruby",
        type_str: "source",
      )

      expect(block.id).to eq("block-1")
      expect(block.title).to eq("Block Title")
      expect(block.attributes).to eq(attributes)
      expect(block.lines).to eq(["Line 1", "Line 2"])
      expect(block.delimiter).to eq("----")
      expect(block.delimiter_char).to eq("-")
      expect(block.delimiter_len).to eq(4)
      expect(block.lang).to eq("ruby")
      expect(block.type_str).to eq("source")
    end

    it "uses default values" do
      block = described_class.new

      expect(block.id).to be_nil
      expect(block.title).to be_nil
      expect(block.attributes).to be_a(Coradoc::Model::AttributeList)
      expect(block.lines).to eq([])
      expect(block.delimiter).to be_nil
      expect(block.delimiter_char).to be_nil
      expect(block.delimiter_len).to be_nil
      expect(block.lang).to be_nil
      expect(block.type_str).to be_nil
    end
  end

  describe "#gen_anchor" do
    it "returns empty string when no anchor" do
      block = described_class.new
      expect(block.gen_anchor).to eq("")
    end

    it "generates anchor when present" do
      block = described_class.new
      allow(block).to receive(:id).and_return("block-1")

      expect(block.gen_anchor).to eq("[[block-1]]\n")
    end
  end

  describe "#gen_title" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates title when present" do
      block = described_class.new(title: "Block Title")
      expect(block.gen_title).to eq(".Block Title\n")
    end

    it "returns empty string when no title" do
      block = described_class.new
      expect(block.gen_title).to eq("")
    end

    it "processes title through Generator" do
      block = described_class.new(title: "Block Title")
      expect(Coradoc::Generator).to receive(:gen_adoc).with("Block Title")
      block.gen_title
    end
  end

  describe "#gen_attributes" do
    it "generates attributes when present" do
      allow(attributes).to receive(:to_asciidoc).with(show_empty: false).and_return("[source,ruby]")

      block = described_class.new(attributes: attributes)
      expect(block.gen_attributes).to eq("[source,ruby]\n")
    end

    it "returns empty string when attributes are empty" do
      allow(attributes).to receive(:to_asciidoc).with(show_empty: false).and_return("")

      block = described_class.new(attributes: attributes)
      expect(block.gen_attributes).to eq("")
    end
  end

  describe "#gen_delimiter" do
    it "generates delimiter with specified character and length" do
      block = described_class.new(delimiter_char: "-", delimiter_len: 4)
      expect(block.gen_delimiter).to eq("----")
    end

    it "handles different characters and lengths" do
      block = described_class.new(delimiter_char: "=", delimiter_len: 6)
      expect(block.gen_delimiter).to eq("======")
    end
  end

  describe "#gen_lines" do
    it "processes lines through Generator" do
      block = described_class.new(lines: ["Line 1", "Line 2"])
      expect(block.gen_lines).to eq("Line 1\nLine 2")
    end

    it "handles empty lines array" do
      block = described_class.new
      expect(block.gen_lines).to eq("")
    end
  end

  describe "inheritance and includes" do
    it "inherits from Attached" do
      expect(described_class.superclass).to eq(Coradoc::Model::Attached)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end
end
