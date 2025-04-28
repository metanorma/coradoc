require "spec_helper"

RSpec.describe Coradoc::Model::TableRow do
  let(:cell1) { instance_double(Coradoc::Model::TableCell, asciidoc?: false) }
  let(:cell2) { instance_double(Coradoc::Model::TableCell, asciidoc?: false) }

  describe ".initialize" do
    it "initializes with columns" do
      row = described_class.new(columns: [cell1, cell2])

      expect(row.columns).to eq([cell1, cell2])
      expect(row.header).to be false
    end

    it "initializes as header row" do
      row = described_class.new(
        columns: [cell1, cell2],
        header: true
      )

      expect(row.columns).to eq([cell1, cell2])
      expect(row.header).to be true
    end

    it "initializes with empty columns" do
      row = described_class.new
      expect(row.columns).to eq([])
      expect(row.header).to be false
    end
  end

  describe "#table_header_row?" do
    it "returns true for header rows" do
      row = described_class.new(header: true)
      expect(row.table_header_row?).to be true
    end

    it "returns false for non-header rows" do
      row = described_class.new(header: false)
      expect(row.table_header_row?).to be false
    end
  end

  describe "#asciidoc?" do
    it "returns true when any column is asciidoc" do
      allow(cell1).to receive(:asciidoc?).and_return(true)
      row = described_class.new(columns: [cell1, cell2])
      expect(row.asciidoc?).to be true
    end

    it "returns false when no column is asciidoc" do
      row = described_class.new(columns: [cell1, cell2])
      expect(row.asciidoc?).to be false
    end

    it "returns false with empty columns" do
      row = described_class.new
      expect(row.asciidoc?).to be false
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |col| col.to_asciidoc }
    end

    context "with regular cells" do
      before do
        allow(cell1).to receive(:to_asciidoc).and_return("| Cell 1")
        allow(cell2).to receive(:to_asciidoc).and_return("| Cell 2")
      end

      it "generates basic row" do
        row = described_class.new(columns: [cell1, cell2])
        expect(row.to_asciidoc).to eq("| Cell 1 | Cell 2\n")
      end

      it "generates header row" do
        row = described_class.new(
          columns: [cell1, cell2],
          header: true
        )
        expect(row.to_asciidoc).to eq("| Cell 1 | Cell 2\n\n")
      end
    end

    context "with asciidoc cells" do
      let(:asciidoc_cell) { instance_double(Coradoc::Model::TableCell, asciidoc?: true) }

      before do
        allow(asciidoc_cell).to receive(:to_asciidoc).and_return("a| Complex *content*")
        allow(cell2).to receive(:to_asciidoc).and_return("| Simple content")
      end

      it "uses newline delimiter" do
        row = described_class.new(columns: [asciidoc_cell, cell2])
        expected_output = "a| Complex *content*\n| Simple content\n\n"
        expect(row.to_asciidoc).to eq(expected_output)
      end
    end

    it "processes columns through Generator" do
      row = described_class.new(columns: [cell1, cell2])
      expect(Coradoc::Generator).to receive(:gen_adoc).with(cell1)
      expect(Coradoc::Generator).to receive(:gen_adoc).with(cell2)
      row.to_asciidoc
    end
  end

  describe "#underline_for" do
    it "returns newline" do
      row = described_class.new
      expect(row.underline_for).to eq("\n")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
