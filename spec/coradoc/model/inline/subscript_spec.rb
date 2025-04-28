require "spec_helper"

RSpec.describe Coradoc::Model::Inline::Subscript do
  describe ".initialize" do
    it "initializes with content" do
      sub = described_class.new(content: "2")
      expect(sub.content).to eq("2")
    end

    it "initializes with no content" do
      sub = described_class.new
      expect(sub.content).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic subscript" do
      sub = described_class.new(content: "2")
      expect(sub.to_asciidoc).to eq("~2~")
    end

    it "processes content through Generator" do
      sub = described_class.new(content: "2")
      expect(Coradoc::Generator).to receive(:gen_adoc).with("2")
      sub.to_asciidoc
    end

    it "handles empty content" do
      sub = described_class.new(content: "")
      expect(sub.to_asciidoc).to eq("~~")
    end

    it "handles nil content" do
      sub = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(sub.to_asciidoc).to eq("~~")
    end

    it "handles multiple characters" do
      sub = described_class.new(content: "123")
      expect(sub.to_asciidoc).to eq("~123~")
    end

    it "handles special characters" do
      sub = described_class.new(content: "x+y")
      expect(sub.to_asciidoc).to eq("~x+y~")
    end

    it "preserves whitespace" do
      sub = described_class.new(content: "n + 1")
      expect(sub.to_asciidoc).to eq("~n + 1~")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "usage examples" do
    it "works for chemical formulas" do
      sub = described_class.new(content: "2")
      expect("H#{sub.to_asciidoc}O").to eq("H~2~O")
    end

    it "works for mathematical expressions" do
      sub = described_class.new(content: "n")
      expect("x#{sub.to_asciidoc}").to eq("x~n~")
    end
  end
end
