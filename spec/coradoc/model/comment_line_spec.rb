# frozen_string_literal: true

RSpec.describe Coradoc::Model::CommentLine do
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
        line_break: "\n\n",
      )
      expect(comment.line_break).to eq("\n\n")
    end

    it "initializes with nil text" do
      comment = described_class.new
      expect(comment.text).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates basic comment line" do
      comment = described_class.new(text: "Sample comment")

      expect(comment.to_asciidoc).to eq("// Sample comment\n")
    end

    it "handles long comments" do
      comment = described_class.new(
        text: "This is a longer comment that spans multiple words",
      )

      expect(comment.to_asciidoc)
        .to eq("// This is a longer comment that spans multiple words\n")
    end

    it "handles empty comment" do
      comment = described_class.new(text: "")

      expect(comment.to_asciidoc).to eq("// \n")
    end

    it "handles nil text" do
      comment = described_class.new

      expect(comment.to_asciidoc).to eq("// \n")
    end

    it "respects custom line break" do
      comment = described_class.new(
        text: "Sample comment",
        line_break: "\n\n",
      )

      expect(comment.to_asciidoc).to eq("// Sample comment\n\n")
    end

    it "preserves special characters in text" do
      comment = described_class.new(text: "Comment with * and _ and #")

      expect(comment.to_asciidoc).to eq("// Comment with * and _ and #\n")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end
end
