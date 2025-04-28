require "spec_helper"

RSpec.describe Coradoc::Model::List do
  describe Coradoc::Model::List::Core do
    # ... existing Core tests ...
  end

  describe Coradoc::Model::List::Ordered do
    # ... existing Ordered tests ...
  end

  describe Coradoc::Model::List::Unordered do
    # ... existing Unordered tests ...
  end

  describe Coradoc::Model::List::Definition do
    let(:item1) { instance_double(Coradoc::Model::ListItem) }
    let(:item2) { instance_double(Coradoc::Model::ListItem) }

    describe ".initialize" do
      it "initializes with default values" do
        list = described_class.new

        expect(list.items).to eq([])
        expect(list.delimiter).to eq("::")
      end

      it "accepts custom delimiter" do
        list = described_class.new(delimiter: ":::")

        expect(list.delimiter).to eq(":::")
      end

      it "accepts items" do
        list = described_class.new(items: [item1, item2])

        expect(list.items).to eq([item1, item2])
      end
    end

    describe "#prefix" do
      it "returns the delimiter" do
        list = described_class.new(delimiter: "::")
        expect(list.prefix).to eq("::")
      end

      it "returns custom delimiter" do
        list = described_class.new(delimiter: ":::")
        expect(list.prefix).to eq(":::")
      end
    end

    describe "#to_asciidoc" do
      before do
        allow(item1).to receive(:to_asciidoc).with("::").and_return("Term 1:: Definition 1\n")
        allow(item2).to receive(:to_asciidoc).with("::").and_return("Term 2:: Definition 2\n")
      end

      it "generates definition list with default delimiter" do
        list = described_class.new(items: [item1, item2])

        expected_output = "\nTerm 1:: Definition 1\nTerm 2:: Definition 2\n"
        expect(list.to_asciidoc).to eq(expected_output)
      end

      it "generates definition list with custom delimiter" do
        allow(item1).to receive(:to_asciidoc).with(":::").and_return("Term 1::: Definition 1\n")
        allow(item2).to receive(:to_asciidoc).with(":::").and_return("Term 2::: Definition 2\n")

        list = described_class.new(
          items: [item1, item2],
          delimiter: ":::"
        )

        expected_output = "\nTerm 1::: Definition 1\nTerm 2::: Definition 2\n"
        expect(list.to_asciidoc).to eq(expected_output)
      end

      it "handles empty list" do
        list = described_class.new
        expect(list.to_asciidoc).to eq("\n")
      end

      it "handles single item" do
        list = described_class.new(items: [item1])

        expected_output = "\nTerm 1:: Definition 1\n"
        expect(list.to_asciidoc).to eq(expected_output)
      end
    end

    describe "inheritance" do
      it "inherits from Base" do
        expect(described_class.superclass).to eq(Coradoc::Model::Base)
      end
    end


  end
end
