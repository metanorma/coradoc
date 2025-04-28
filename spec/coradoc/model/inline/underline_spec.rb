require "spec_helper"

RSpec.describe Coradoc::Model::Inline::Underline do
  describe ".initialize" do
    it "initializes with text" do
      underline = described_class.new(text: "underlined text")
      expect(underline.text).to eq("underlined text")
    end

    it "initializes with no attributes" do
      underline = described_class.new
      expect(underline.text).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates basic underline" do
      underline = described_class.new(text: "underlined text")
      expect(underline.to_asciidoc).to eq("[.underline]#underlined text#")
    end

    it "handles empty text" do
      underline = described_class.new(text: "")
      expect(underline.to_asciidoc).to eq("[.underline]##")
    end

    it "handles nil text" do
      underline = described_class.new
      expect(underline.to_asciidoc).to eq("[.underline]##")
    end

    it "handles multiline text" do
      underline = described_class.new(text: "line 1\nline 2")
      expect(underline.to_asciidoc).to eq("[.underline]#line 1\nline 2#")
    end

    it "preserves whitespace" do
      underline = described_class.new(text: "  spaced  text  ")
      expect(underline.to_asciidoc).to eq("[.underline]#  spaced  text  #")
    end

    it "preserves special characters" do
      underline = described_class.new(text: "text with * and _ and #")
      expect(underline.to_asciidoc).to eq("[.underline]#text with * and _ and ##")
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
      underline = described_class.new(text: "important")
      expect("This is #{underline.to_asciidoc} text").to eq("This is [.underline]#important# text")
    end

    it "works with multiple words" do
      underline = described_class.new(text: "very important note")
      expect("A #{underline.to_asciidoc}").to eq("A [.underline]#very important note#")
    end

    it "works at start of text" do
      underline = described_class.new(text: "Important:")
      expect("#{underline.to_asciidoc} read this").to eq("[.underline]#Important:# read this")
    end

    it "works at end of text" do
      underline = described_class.new(text: "important")
      expect("This is #{underline.to_asciidoc}").to eq("This is [.underline]#important#")
    end
  end
end
