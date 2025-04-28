# frozen_string_literal: true

RSpec.describe Coradoc::Model::Admonition do
  describe ".initialize" do
    it "initializes with basic attributes" do
      admonition = described_class.new(
        content: "Watch out!",
        type: :warning
      )

      expect(admonition.content).to eq("Watch out!")
      expect(admonition.type).to eq("warning")
      expect(admonition.type).to be_a String
      expect(admonition.line_break).to eq("")
    end

    it "accepts custom line break" do
      admonition = described_class.new(
        content: "Watch out!",
        type: :warning,
        line_break: "\n"
      )

      expect(admonition.line_break).to eq("\n")
    end

    it "initializes with no attributes" do
      admonition = described_class.new

      expect(admonition.content).to be_nil
      expect(admonition.type).to be_nil
      expect(admonition.line_break).to eq("")
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic admonition" do
      admonition = described_class.new(
        content: "Watch out!",
        type: :warning
      )

      expect(admonition.to_asciidoc).to eq("WARNING: Watch out!")
    end

    it "includes line break when specified" do
      admonition = described_class.new(
        content: "Watch out!",
        type: :warning,
        line_break: "\n"
      )

      expect(admonition.to_asciidoc).to eq("WARNING: Watch out!\n")
    end

    it "converts type to uppercase" do
      admonition = described_class.new(
        content: "Important info",
        type: :important
      )

      expect(admonition.to_asciidoc).to eq("IMPORTANT: Important info")
    end

    it "handles multiline content" do
      content = "First line\nSecond line"
      admonition = described_class.new(
        content: content,
        type: :note
      )

      expect(admonition.to_asciidoc).to eq("NOTE: First line\nSecond line")
    end

    it "processes content through Generator.gen_adoc" do
      content = "Formatted content"
      admonition = described_class.new(
        content: content,
        type: :tip
      )

      expect(Coradoc::Generator).to receive(:gen_adoc).with(content)
      admonition.to_asciidoc
    end

    it "handles nil content" do
      admonition = described_class.new(type: :caution)
      expect(admonition.to_asciidoc).to eq("CAUTION: ")
    end

    it "handles nil type" do
      admonition = described_class.new(content: "Content")
      expect(admonition.to_asciidoc).to eq(": Content")
    end
  end

  describe "inheritance" do
    it "inherits from Attached" do
      expect(described_class.superclass).to eq(Coradoc::Model::Attached)
    end
  end



  describe "common admonition types" do
    let(:content) { "Test content" }

    it "supports NOTE type" do
      admonition = described_class.new(content: content, type: :note)
      expect(admonition.to_asciidoc).to eq("NOTE: Test content")
    end

    it "supports TIP type" do
      admonition = described_class.new(content: content, type: :tip)
      expect(admonition.to_asciidoc).to eq("TIP: Test content")
    end

    it "supports IMPORTANT type" do
      admonition = described_class.new(content: content, type: :important)
      expect(admonition.to_asciidoc).to eq("IMPORTANT: Test content")
    end

    it "supports CAUTION type" do
      admonition = described_class.new(content: content, type: :caution)
      expect(admonition.to_asciidoc).to eq("CAUTION: Test content")
    end

    it "supports WARNING type" do
      admonition = described_class.new(content: content, type: :warning)
      expect(admonition.to_asciidoc).to eq("WARNING: Test content")
    end
  end
end
