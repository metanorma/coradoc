# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Superscript do
  describe ".initialize" do
    it "initializes with content" do
      sup = described_class.new(content: "2")
      expect(sup.content).to eq("2")
    end

    it "initializes with no content" do
      sup = described_class.new
      expect(sup.content).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic superscript" do
      sup = described_class.new(content: "2")
      expect(sup.to_asciidoc).to eq("^2^")
    end

    it "processes content through Generator" do
      sup = described_class.new(content: "2")
      expect(Coradoc::Generator).to receive(:gen_adoc).with("2")
      sup.to_asciidoc
    end

    it "handles empty content" do
      sup = described_class.new(content: "")
      expect(sup.to_asciidoc).to eq("")
    end

    it "handles nil content" do
      sup = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(sup.to_asciidoc).to eq("")
    end

    it "handles multiple characters" do
      sup = described_class.new(content: "123")
      expect(sup.to_asciidoc).to eq("^123^")
    end

    it "handles special characters" do
      sup = described_class.new(content: "n+1")
      expect(sup.to_asciidoc).to eq("^n+1^")
    end

    it "handles superscript characters" do
      sup = described_class.new(content: "x^ ^a^b^ ^y")
      expect(sup.to_asciidoc).to eq("^x{pass:[^]} {pass:[^]}a{pass:[^]}b{pass:[^]} {pass:[^]}y^")
    end

    it "preserves whitespace" do
      sup = described_class.new(content: "x + y")
      expect(sup.to_asciidoc).to eq("^x + y^")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "usage examples" do
    it "works for exponents" do
      sup = described_class.new(content: "2")
      expect("x#{sup.to_asciidoc}").to eq("x^2^")
    end

    it "works for ordinal numbers" do
      sup = described_class.new(content: "st")
      expect("1#{sup.to_asciidoc}").to eq("1^st^")
    end

    it "works for mathematical expressions" do
      sup = described_class.new(content: "n+1")
      expect("x#{sup.to_asciidoc}").to eq("x^n+1^")
    end

    it "works for chemical notations" do
      sup = described_class.new(content: "+")
      expect("Na#{sup.to_asciidoc}").to eq("Na^+^")
    end
  end
end
