# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::CrossReference do
  describe ".initialize" do
    it "initializes with href" do
      xref = described_class.new(href: "section-1")

      expect(xref.href).to eq("section-1")
      expect(xref.args).to be_nil
    end

    it "accepts href and args" do
      xref = described_class.new(
        href: "section-1",
        args: ["Section 1", "Introduction"]
      )

      expect(xref.href).to eq("section-1")
      expect(xref.args).to eq(["Section 1", "Introduction"])
    end

    it "initializes with empty attributes" do
      xref = described_class.new

      expect(xref.href).to be_nil
      expect(xref.args).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with href only" do
      it "generates basic cross reference" do
        xref = described_class.new(href: "section-1")
        expect(xref.to_asciidoc).to eq("<<section-1>>")
      end

      it "handles special characters in href" do
        xref = described_class.new(href: "section-1.2_3")
        expect(xref.to_asciidoc).to eq("<<section-1.2_3>>")
      end
    end

    context "with href and args" do
      it "generates cross reference with single argument" do
        xref = described_class.new(
          href: "section-1",
          args: ["Section 1"]
        )

        expect(xref.to_asciidoc).to eq("<<section-1,Section 1>>")
      end

      it "generates cross reference with multiple arguments" do
        xref = described_class.new(
          href: "section-1",
          args: ["Section 1", "Introduction"]
        )

        expect(xref.to_asciidoc).to eq("<<section-1,Section 1,Introduction>>")
      end

      it "processes args through Generator" do
        args = ["Section 1", "Introduction"]
        xref = described_class.new(
          href: "section-1",
          args: args
        )

        args.each do |arg|
          expect(Coradoc::Generator).to receive(:gen_adoc).with(arg)
        end

        xref.to_asciidoc
      end

      it "handles empty args array" do
        xref = described_class.new(
          href: "section-1",
          args: []
        )

        expect(xref.to_asciidoc).to eq("<<section-1>>")
      end

      it "handles args with empty strings" do
        xref = described_class.new(
          href: "section-1",
          args: ["", ""]
        )

        expect(xref.to_asciidoc).to eq("<<section-1>>")
      end
    end

    it "handles nil href" do
      xref = described_class.new
      expect(xref.to_asciidoc).to eq("<<>>")
    end

    it "handles empty href" do
      xref = described_class.new(href: "")
      expect(xref.to_asciidoc).to eq("<<>>")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
