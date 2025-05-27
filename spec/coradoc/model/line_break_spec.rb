# frozen_string_literal: true

RSpec.describe Coradoc::Model::LineBreak do
  describe ".initialize" do
    it "initializes with empty line break by default" do
      line_break = described_class.new
      expect(line_break.line_break).to eq("")
    end

    it "accepts custom line break" do
      line_break = described_class.new(line_break: "\n")
      expect(line_break.line_break).to eq("\n")
    end

    it "accepts multiple newlines" do
      line_break = described_class.new(line_break: "\n\n\n")
      expect(line_break.line_break).to eq("\n\n\n")
    end
  end

  describe "#to_asciidoc" do
    it "returns empty string for default line break" do
      line_break = described_class.new
      expect(line_break.to_asciidoc).to eq("")
    end

    it "returns single newline" do
      line_break = described_class.new(line_break: "\n")
      expect(line_break.to_asciidoc).to eq("\n")
    end

    it "returns multiple newlines" do
      line_break = described_class.new(line_break: "\n\n")
      expect(line_break.to_asciidoc).to eq("\n\n")
    end

    it "preserves custom line break exactly" do
      custom_break = "\r\n"
      line_break = described_class.new(line_break: custom_break)
      expect(line_break.to_asciidoc).to eq(custom_break)
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end
end
