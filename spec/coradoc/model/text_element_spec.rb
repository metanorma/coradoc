# frozen_string_literal: true

RSpec.describe Coradoc::Model::TextElement do
  describe ".initialize" do
    it "initializes with all attributes" do
      element = described_class.new(
        id: "text-1",
        content: "Sample text",
        line_break: "\n"
      )

      expect(element.id).to eq("text-1")
      expect(element.content).to eq("Sample text")
      expect(element.line_break).to eq("\n")
    end

    it "uses default values" do
      element = described_class.new

      expect(element.id).to be_nil
      expect(element.content).to eq("")
      expect(element.line_break).to eq("")
    end

    it "accepts partial attributes" do
      element = described_class.new(content: "Sample text")

      expect(element.id).to be_nil
      expect(element.content).to eq("Sample text")
      expect(element.line_break).to eq("")
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic text" do
      element = described_class.new(content: "Sample text")
      expect(element.to_asciidoc).to eq("Sample text")
    end

    it "includes line break when specified" do
      element = described_class.new(
        content: "Sample text",
        line_break: "\n"
      )
      expect(element.to_asciidoc).to eq("Sample text\n")
    end

    it "processes content through Generator" do
      element = described_class.new(content: "Sample text")
      expect(Coradoc::Generator).to receive(:gen_adoc).with("Sample text")
      element.to_asciidoc
    end

    it "handles empty content" do
      element = described_class.new
      expect(element.to_asciidoc).to eq("")
    end

    it "handles multiline content" do
      element = described_class.new(
        content: "Line 1\nLine 2",
        line_break: "\n"
      )
      expect(element.to_asciidoc).to eq("Line 1\nLine 2\n")
    end

    it "preserves special characters" do
      element = described_class.new(content: "Text with * and _ and #")
      expect(element.to_asciidoc).to eq("Text with * and _ and #")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "as base class" do
    let(:subclass) do
      Class.new(described_class) do
        def to_asciidoc
          "[custom]#{super}"
        end
      end
    end

    it "can be extended by subclasses" do
      element = subclass.new(content: "Sample text")
      expect(element.to_asciidoc).to eq("[custom]Sample text")
    end

    it "provides default attributes to subclasses" do
      element = subclass.new
      expect(element.content).to eq("")
      expect(element.line_break).to eq("")
    end
  end

  describe "usage examples" do
    it "works for simple paragraphs" do
      element = described_class.new(
        content: "A simple paragraph.",
        line_break: "\n\n"
      )
      expect(element.to_asciidoc).to eq("A simple paragraph.\n\n")
    end

    it "works for formatted text" do
      element = described_class.new(
        content: "*bold* and _italic_",
        line_break: "\n"
      )
      expect(element.to_asciidoc).to eq("*bold* and _italic_\n")
    end
  end
end
