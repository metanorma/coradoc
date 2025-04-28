# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Quotation do
  describe ".initialize" do
    it "initializes with content" do
      quote = described_class.new(content: "quoted text")
      expect(quote.content).to eq("quoted text")
    end

    it "initializes with no content" do
      quote = described_class.new
      expect(quote.content).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic quotation" do
      quote = described_class.new(content: "quoted text")
      expect(quote.to_asciidoc).to eq("\"quoted text\"")
    end

    it "processes content through Generator" do
      quote = described_class.new(content: "quoted text")
      expect(Coradoc::Generator).to receive(:gen_adoc).with("quoted text")
      quote.to_asciidoc
    end

    it "preserves leading whitespace" do
      quote = described_class.new(content: "  quoted text")
      expect(quote.to_asciidoc).to eq("  \"quoted text\"")
    end

    it "preserves trailing whitespace" do
      quote = described_class.new(content: "quoted text  ")
      expect(quote.to_asciidoc).to eq("\"quoted text\"  ")
    end

    it "preserves both leading and trailing whitespace" do
      quote = described_class.new(content: "  quoted text  ")
      expect(quote.to_asciidoc).to eq("  \"quoted text\"  ")
    end

    it "strips internal whitespace" do
      quote = described_class.new(content: "quoted   text")
      expect(quote.to_asciidoc).to eq("\"quoted   text\"")
    end

    it "handles empty content" do
      quote = described_class.new(content: "")
      expect(quote.to_asciidoc).to eq("\"\"")
    end

    it "handles nil content" do
      quote = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(quote.to_asciidoc).to eq("\"\"")
    end

    it "handles content with quotes" do
      quote = described_class.new(content: "He said \"hello\"")
      expect(quote.to_asciidoc).to eq("\"He said \"hello\"\"")
    end

    it "handles multiline content" do
      quote = described_class.new(content: "line 1\nline 2")
      expect(quote.to_asciidoc).to eq("\"line 1\nline 2\"")
    end

    context "with special whitespace patterns" do
      it "handles tabs" do
        quote = described_class.new(content: "\tquoted text\t")
        expect(quote.to_asciidoc).to eq("\t\"quoted text\"\t")
      end

      it "handles mixed whitespace" do
        quote = described_class.new(content: " \t quoted text \t ")
        expect(quote.to_asciidoc).to eq(" \t \"quoted text\" \t ")
      end
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
