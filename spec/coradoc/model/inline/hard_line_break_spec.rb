# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::HardLineBreak do
  describe ".initialize" do
    it "can be instantiated" do
      expect { described_class.new }
        .not_to raise_error
    end
  end

  describe "#to_asciidoc" do
    it "generates hard line break syntax" do
      break_element = described_class.new
      expect(break_element.to_asciidoc).to eq(" +\n")
    end

    it "is consistent across multiple instances" do
      break1 = described_class.new
      break2 = described_class.new

      expect(break1.to_asciidoc).to eq(break2.to_asciidoc)
    end

    it "includes both plus sign and newline" do
      break_element = described_class.new
      result = break_element.to_asciidoc

      expect(result).to include("+")
      expect(result).to include("\n")
      expect(result).to start_with(" ")
    end

    it "has correct length" do
      break_element = described_class.new
      expect(break_element.to_asciidoc.length).to eq(3)
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "usage in text" do
    it "can be concatenated with other text" do
      break_element = described_class.new
      result = "First line#{break_element.to_asciidoc}Second line"
      expect(result).to eq("First line +\nSecond line")
    end
  end
end
