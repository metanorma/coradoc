# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Italic do
  describe ".initialize" do
    it "initializes with content" do
      italic = described_class.new(content: "italic text")

      expect(italic.content).to eq("italic text")
      expect(italic.unconstrained).to be true
    end

    it "accepts unconstrained parameter" do
      italic = described_class.new(
        content: "italic text",
        unconstrained: false
      )

      expect(italic.content).to eq("italic text")
      expect(italic.unconstrained).to be false
    end

    it "uses default values" do
      italic = described_class.new

      expect(italic.content).to be_nil
      expect(italic.unconstrained).to be true
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with unconstrained true (default)" do
      it "uses double asterisks" do
        italic = described_class.new(content: "italic text")
        expect(italic.to_asciidoc).to eq("__italic text__")
      end

      it "processes content through Generator" do
        italic = described_class.new(content: "italic text")
        expect(Coradoc::Generator).to receive(:gen_adoc).with("italic text")
        italic.to_asciidoc
      end
    end

    context "with unconstrained false" do
      it "uses single asterisk" do
        italic = described_class.new(
          content: "italic text",
          unconstrained: false
        )
        expect(italic.to_asciidoc).to eq("_italic text_")
      end
    end

    it "handles multiline content" do
      italic = described_class.new(content: "line 1\nline 2")
      expect(italic.to_asciidoc).to eq("__line 1\nline 2__")
    end

    it "handles empty content" do
      italic = described_class.new(content: "")
      expect(italic.to_asciidoc).to eq("")
    end

    it "handles nil content" do
      italic = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(italic.to_asciidoc).to eq("")
    end

    it "preserves special characters in content" do
      italic = described_class.new(content: "text ` with * and _ and #")
      expect(italic.to_asciidoc).to eq("__text ` with * and \\_ and #__")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
