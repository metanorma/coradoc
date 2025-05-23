# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Bold do
  describe ".initialize" do
    it "initializes with content" do
      bold = described_class.new(content: "bold text")

      expect(bold.content).to eq("bold text")
      expect(bold.unconstrained).to be true
    end

    it "accepts unconstrained parameter" do
      bold = described_class.new(
        content: "bold text",
        unconstrained: false
      )

      expect(bold.content).to eq("bold text")
      expect(bold.unconstrained).to be false
    end

    it "uses default values" do
      bold = described_class.new

      expect(bold.content).to be_nil
      expect(bold.unconstrained).to be true
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with unconstrained true (default)" do
      it "uses double asterisks" do
        bold = described_class.new(content: "bold text")
        expect(bold.to_asciidoc).to eq("**bold text**")
      end

      it "processes content through Generator" do
        bold = described_class.new(content: "bold text")
        expect(Coradoc::Generator).to receive(:gen_adoc).with("bold text")
        bold.to_asciidoc
      end
    end

    context "with unconstrained false" do
      it "uses single asterisk" do
        bold = described_class.new(
          content: "bold text",
          unconstrained: false
        )
        expect(bold.to_asciidoc).to eq("*bold text*")
      end
    end

    it "handles multiline content" do
      bold = described_class.new(content: "line 1\nline 2")
      expect(bold.to_asciidoc).to eq("**line 1\nline 2**")
    end

    it "handles empty content" do
      bold = described_class.new(content: "")
      expect(bold.to_asciidoc).to eq("")
    end

    it "handles nil content" do
      bold = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(bold.to_asciidoc).to eq("")
    end

    it "preserves special characters in content" do
      bold = described_class.new(content: "text with * and _ and #")
      expect(bold.to_asciidoc).to eq("**text with \\* and _ and #**")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
