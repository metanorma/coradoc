# frozen_string_literal: true

RSpec.describe Coradoc::Model::Table do
  let(:rows) do
    [
      instance_double("TableRow", to_asciidoc: "| Header 1 | Header 2\n"),
      instance_double("TableRow", to_asciidoc: "| Cell 1 | Cell 2\n"),
    ]
  end
  let(:attrs) { instance_double(Coradoc::Model::AttributeList) }

  describe ".initialize" do
    it "initializes with all attributes" do
      table = described_class.new(
        id: "table-1",
        title: "Sample Table",
        rows: rows,
        attrs: attrs,
      )

      expect(table.id).to eq("table-1")
      expect(table.title).to eq("Sample Table")
      expect(table.rows).to eq(rows)
      expect(table.attrs).to eq(attrs)
    end

    it "initializes with minimal attributes" do
      table = described_class.new(rows: rows)

      expect(table.id).to be_nil
      expect(table.title).to be_nil
      expect(table.rows).to eq(rows)
      expect(table.attrs).to be_nil
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    it "generates basic table" do
      table = described_class.new(rows: rows)

      expected_output = "\n\n|===\n| Header 1 | Header 2\n| Cell 1 | Cell 2\n\n|===\n"
      expect(table.to_asciidoc).to eq(expected_output)
    end

    it "includes title when present" do
      table = described_class.new(title: "Sample Table", rows: rows)

      expected_output = "\n\n.Sample Table\n|===\n| Header 1 | Header 2\n| Cell 1 | Cell 2\n\n|===\n"
      expect(table.to_asciidoc).to eq(expected_output)
    end

    it "includes anchor when present" do
      anchor = instance_double(
        Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[table-1]]",
      )

      table = described_class.new(rows: rows)
      allow(table).to receive(:anchor).and_return(anchor)

      expected_output = "\n\n[[table-1]]\n|===\n| Header 1 | Header 2\n| Cell 1 | Cell 2\n\n|===\n"
      expect(table.to_asciidoc).to eq(expected_output)
    end

    it "includes attributes when present" do
      allow(attrs).to receive(:to_s).and_return("[cols=\"2*\"]")
      allow(attrs).to receive(:to_asciidoc).and_return("[cols=\"2*\"]")

      table = described_class.new(rows: rows, attrs: attrs)

      expected_output = "\n\n[cols=\"2*\"]\n|===\n| Header 1 | Header 2\n| Cell 1 | Cell 2\n\n|===\n"
      expect(table.to_asciidoc).to eq(expected_output)
    end

    it "includes all elements when present" do
      anchor = instance_double(
        Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[table-1]]",
      )
      allow(attrs).to receive(:to_s).and_return("[cols=\"2*\"]")
      allow(attrs).to receive(:to_asciidoc).and_return("[cols=\"2*\"]")

      table = described_class.new(
        title: "Sample Table",
        rows: rows,
        attrs: attrs,
      )
      allow(table).to receive(:anchor).and_return(anchor)

      expected_output = "\n\n[[table-1]]\n[cols=\"2*\"]\n.Sample Table\n|===\n| Header 1 | Header 2\n| Cell 1 | Cell 2\n\n|===\n"
      expect(table.to_asciidoc).to eq(expected_output)
    end

    it "processes title through Generator" do
      table = described_class.new(title: "Sample Table", rows: rows)

      expect(Coradoc::Generator).to receive(:gen_adoc).with("Sample Table")
      table.to_asciidoc
    end
  end

  describe "inheritance and includes" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end
end
