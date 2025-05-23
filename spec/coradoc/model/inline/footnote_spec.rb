# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Footnote do
  describe ".initialize" do
    it "initializes with text and id" do
      footnote = described_class.new(
        text: "See reference",
        id: "ref1"
      )

      expect(footnote.text).to eq("See reference")
      expect(footnote.id).to eq("ref1")
    end

    it "initializes with text only" do
      footnote = described_class.new(text: "See reference")

      expect(footnote.text).to eq("See reference")
      expect(footnote.id).to be_nil
    end

    it "initializes with no attributes" do
      footnote = described_class.new

      expect(footnote.text).to be_nil
      expect(footnote.id).to be_nil
    end
  end

  describe "#to_asciidoc" do
    context "with id" do
      it "generates footnote with id" do
        footnote = described_class.new(
          text: "See reference",
          id: "ref1"
        )

        expect(footnote.to_asciidoc).to eq("footnote:ref1[See reference]")
      end

      it "handles empty text" do
        footnote = described_class.new(
          text: "",
          id: "ref1"
        )

        expect(footnote.to_asciidoc).to eq("footnote:ref1[]")
      end
    end

    context "without id" do
      it "generates footnote without id" do
        footnote = described_class.new(text: "See reference")
        expect(footnote.to_asciidoc).to eq("footnote:[See reference]")
      end

      it "handles empty text" do
        footnote = described_class.new(text: "")
        expect(footnote.to_asciidoc).to eq("footnote:[]")
      end
    end

    it "handles multiline text" do
      footnote = described_class.new(text: "Line 1\nLine 2")
      expect(footnote.to_asciidoc).to eq("footnote:[Line 1\nLine 2]")
    end

    it "preserves special characters in text" do
      footnote = described_class.new(text: "See * and _ and #")
      expect(footnote.to_asciidoc).to eq("footnote:[See * and _ and #]")
    end

    it "preserves special characters in id" do
      footnote = described_class.new(
        text: "See reference",
        id: "ref-1_2"
      )
      expect(footnote.to_asciidoc).to eq("footnote:ref-1_2[See reference]")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "usage examples" do
    it "works in sentences" do
      footnote = described_class.new(text: "See reference")
      expect("Some text#{footnote.to_asciidoc}").to eq("Some textfootnote:[See reference]")
    end

    it "allows referencing same footnote multiple times" do
      footnote = described_class.new(
        text: "See reference",
        id: "ref1"
      )
      first_use = "First use#{footnote.to_asciidoc}"
      second_use = "Second use#{footnote.to_asciidoc}"

      expect(first_use).to eq("First usefootnote:ref1[See reference]")
      expect(second_use).to eq("Second usefootnote:ref1[See reference]")
    end
  end
end
