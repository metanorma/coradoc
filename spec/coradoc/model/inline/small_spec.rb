require "spec_helper"

RSpec.describe Coradoc::Model::Inline::Small do
  describe ".initialize" do
    it "initializes with text" do
      small = described_class.new(text: "small text")
      expect(small.text).to eq("small text")
    end

    it "initializes with no attributes" do
      small = described_class.new
      expect(small.text).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates basic small text" do
      small = described_class.new(text: "small text")
      expect(small.to_asciidoc).to eq("[.small]#small text#")
    end

    it "handles empty text" do
      small = described_class.new(text: "")
      expect(small.to_asciidoc).to eq("[.small]##")
    end

    it "handles nil text" do
      small = described_class.new
      expect(small.to_asciidoc).to eq("[.small]##")
    end

    it "handles multiline text" do
      small = described_class.new(text: "line 1\nline 2")
      expect(small.to_asciidoc).to eq("[.small]#line 1\nline 2#")
    end

    it "preserves whitespace" do
      small = described_class.new(text: "  spaced  text  ")
      expect(small.to_asciidoc).to eq("[.small]#  spaced  text  #")
    end

    it "preserves special characters" do
      small = described_class.new(text: "text with * and _ and #")
      expect(small.to_asciidoc).to eq("[.small]#text with * and _ and ##")
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
    end
  end

  describe "usage examples" do
    it "works in sentences" do
      small = described_class.new(text: "side note")
      expect("Main text (#{small.to_asciidoc})").to eq("Main text ([.small]#side note#)")
    end

    it "works with multiple words" do
      small = described_class.new(text: "additional information")
      expect("See #{small.to_asciidoc}").to eq("See [.small]#additional information#")
    end

    it "works for annotations" do
      small = described_class.new(text: "*Note:")
      expect("#{small.to_asciidoc} main text").to eq("[.small]#*Note:# main text")
    end

    it "works for parenthetical text" do
      small = described_class.new(text: "(optional)")
      expect("Field name #{small.to_asciidoc}").to eq("Field name [.small]#(optional)#")
    end
  end
end
