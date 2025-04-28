require "spec_helper"

RSpec.describe Coradoc::Model::Revision do
  let(:date) { Date.new(2024, 1, 1) }

  describe ".initialize" do
    it "initializes with all attributes" do
      revision = described_class.new(
        number: "1.0",
        date: date,
        remark: "Initial release"
      )

      expect(revision.number).to eq("1.0")
      expect(revision.date).to eq(date)
      expect(revision.remark).to eq("Initial release")
    end

    it "accepts partial attributes" do
      revision = described_class.new(number: "1.0")

      expect(revision.number).to eq("1.0")
      expect(revision.date).to be_nil
      expect(revision.remark).to be_nil
    end

    it "initializes with no attributes" do
      revision = described_class.new

      expect(revision.number).to be_nil
      expect(revision.date).to be_nil
      expect(revision.remark).to be_nil
    end
  end

  describe "#to_asciidoc" do
    context "with number only" do
      it "generates version number format" do
        revision = described_class.new(number: "1.0")
        expect(revision.to_asciidoc).to eq("v1.0\n")
      end
    end

    context "with number and date" do
      it "generates version with date format" do
        revision = described_class.new(
          number: "1.0",
          date: date
        )

        expect(revision.to_asciidoc).to eq("1.0, 2024-01-01\n")
      end
    end

    context "with number and remark" do
      it "generates version with remark format" do
        revision = described_class.new(
          number: "1.0",
          remark: "Initial release"
        )

        expect(revision.to_asciidoc).to eq("1.0: Initial release\n")
      end
    end

    context "with all attributes" do
      it "generates complete revision format" do
        revision = described_class.new(
          number: "1.0",
          date: date,
          remark: "Initial release"
        )

        expect(revision.to_asciidoc).to eq("1.0, 2024-01-01: Initial release\n")
      end
    end

    it "handles nil number" do
      revision = described_class.new(
        date: date,
        remark: "Initial release"
      )

      expect(revision.to_asciidoc).to eq(", 2024-01-01: Initial release\n")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end



  describe "attribute types" do
    it "accepts string number" do
      revision = described_class.new(number: "1.0.0")
      expect(revision.number).to eq("1.0.0")
    end

    it "accepts Date object" do
      revision = described_class.new(date: date)
      expect(revision.date).to eq(date)
    end

    it "validates date type" do
      expect { described_class.new(date: "2024-01-01") }
        .to raise_error(TypeError)
    end
  end
end
