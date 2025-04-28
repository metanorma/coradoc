# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Highlight do
  describe ".initialize" do
    it "initializes with content" do
      highlight = described_class.new(content: "highlighted text")

      expect(highlight.content).to eq("highlighted text")
      expect(highlight.unconstrained).to be false
    end

    it "accepts unconstrained parameter" do
      highlight = described_class.new(
        content: "highlighted text",
        unconstrained: true
      )

      expect(highlight.content).to eq("highlighted text")
      expect(highlight.unconstrained).to be true
    end

    it "uses default values" do
      highlight = described_class.new

      expect(highlight.content).to be_nil
      expect(highlight.unconstrained).to be false
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with unconstrained false (default)" do
      it "uses single hash" do
        highlight = described_class.new(content: "highlighted text")
        expect(highlight.to_asciidoc).to eq("#highlighted text")
      end

      it "processes content through Generator" do
        highlight = described_class.new(content: "highlighted text")
        expect(Coradoc::Generator).to receive(:gen_adoc).with("highlighted text")
        highlight.to_asciidoc
      end
    end

    context "with unconstrained true" do
      it "uses double hash" do
        highlight = described_class.new(
          content: "highlighted text",
          unconstrained: true
        )
        expect(highlight.to_asciidoc).to eq("##highlighted text")
      end
    end

    it "handles multiline content" do
      highlight = described_class.new(content: "line 1\nline 2")
      expect(highlight.to_asciidoc).to eq("#line 1\nline 2")
    end

    it "handles empty content" do
      highlight = described_class.new(content: "")
      expect(highlight.to_asciidoc).to eq("#")
    end

    it "handles nil content" do
      highlight = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(highlight.to_asciidoc).to eq("#")
    end

    it "preserves special characters in content" do
      highlight = described_class.new(content: "text with * and _ and #")
      expect(highlight.to_asciidoc).to eq("#text with * and _ and #")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "usage examples" do
    it "works for marking important text" do
      highlight = described_class.new(content: "important")
      expect("This is #{highlight.to_asciidoc}!").to eq("This is #important#!")
    end

    it "works for marking entire phrases" do
      highlight = described_class.new(
        content: "very important note",
        unconstrained: true
      )
      expect("A #{highlight.to_asciidoc}").to eq("A ##very important note")
    end

    it "works with punctuation" do
      highlight = described_class.new(content: "Note:")
      expect("#{highlight.to_asciidoc} read this").to eq("#Note#: read this")
    end
  end
end
