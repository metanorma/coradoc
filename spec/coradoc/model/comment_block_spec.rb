require "spec_helper"

RSpec.describe Coradoc::Model::CommentBlock do
  describe ".initialize" do
    it "initializes with text" do
      comment = described_class.new(text: "Sample comment")

      expect(comment.text).to eq("Sample comment")
      expect(comment.line_break).to eq("\n")
    end

    it "uses default line break when not provided" do
      comment = described_class.new(text: "Sample comment")
      expect(comment.line_break).to eq("\n")
    end

    it "accepts custom line break" do
      comment = described_class.new(
        text: "Sample comment",
        line_break: "\n\n"
      )
      expect(comment.line_break).to eq("\n\n")
    end

    it "initializes with nil text" do
      comment = described_class.new
      expect(comment.text).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates basic comment block" do
      comment = described_class.new(text: "Sample comment")

      expected_output = "////\nSample comment\n////\n"
      expect(comment.to_asciidoc).to eq(expected_output)
    end

    it "handles multiline comments" do
      text = "First line\nSecond line\nThird line"
      comment = described_class.new(text: text)

      expected_output = "////\nFirst line\nSecond line\nThird line\n////\n"
      expect(comment.to_asciidoc).to eq(expected_output)
    end

    it "handles empty comment" do
      comment = described_class.new(text: "")

      expected_output = "////\n\n////\n"
      expect(comment.to_asciidoc).to eq(expected_output)
    end

    it "handles nil text" do
      comment = described_class.new

      expected_output = "////\n\n////\n"
      expect(comment.to_asciidoc).to eq(expected_output)
    end

    it "respects custom line break" do
      comment = described_class.new(
        text: "Sample comment",
        line_break: "\n\n"
      )

      expected_output = "////\nSample comment\n////\n\n"
      expect(comment.to_asciidoc).to eq(expected_output)
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "asciidoc mapping" do
    it "maps text attribute correctly" do
      mapping = described_class.asciidoc_mapping.mappings
      text_mapping = mapping.find { |m| m.instance_variable_get(:@to) == :text }

      expect(text_mapping).not_to be_nil
      expect(text_mapping.instance_variable_get(:@name)).to eq("text")
    end
  end
end
