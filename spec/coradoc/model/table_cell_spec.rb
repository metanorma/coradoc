# frozen_string_literal: true

RSpec.describe Coradoc::Model::TableCell do
  describe ".initialize" do
    it "initializes with all attributes" do
      cell = described_class.new(
        id: "cell-1",
        content: "Cell content",
        colrowattr: "2.3+",
        alignattr: "^",
        style: "a"
      )

      expect(cell.id).to eq("cell-1")
      expect(cell.content).to eq("Cell content")
      expect(cell.colrowattr).to eq("2.3+")
      expect(cell.alignattr).to eq("^")
      expect(cell.style).to eq("a")
    end

    it "uses default values" do
      cell = described_class.new

      expect(cell.id).to be_nil
      expect(cell.content).to eq("")
      expect(cell.colrowattr).to eq("")
      expect(cell.alignattr).to eq("")
      expect(cell.style).to eq("")
    end
  end

  describe "#asciidoc?" do
    it "returns true when style includes 'a'" do
      cell = described_class.new(style: "a")
      expect(cell.asciidoc?).to be true
    end

    it "returns false when style doesn't include 'a'" do
      cell = described_class.new(style: "m")
      expect(cell.asciidoc?).to be false
    end

    it "returns false with empty style" do
      cell = described_class.new
      expect(cell.asciidoc?).to be false
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
      allow(Coradoc).to receive(:strip_unicode) { |content| content }
      allow(Coradoc).to receive(:a_single?) { |content, type| content.is_a?(String) }
    end

    it "generates basic cell" do
      cell = described_class.new(content: "Cell content")
      expect(cell.to_asciidoc).to eq("| Cell content")
    end

    it "includes column/row attributes" do
      cell = described_class.new(
        content: "Cell content",
        colrowattr: "2.3+"
      )
      expect(cell.to_asciidoc).to eq("2.3+| Cell content")
    end

    it "includes alignment attributes" do
      cell = described_class.new(
        content: "Cell content",
        alignattr: "^"
      )
      expect(cell.to_asciidoc).to eq("^| Cell content")
    end

    it "includes style" do
      cell = described_class.new(
        content: "Cell content",
        style: "a"
      )
      expect(cell.to_asciidoc).to eq("a| Cell content")
    end

    it "includes anchor when present" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[cell-1]]"
      )

      cell = described_class.new(content: "Cell content")
      allow(cell).to receive(:anchor).and_return(anchor)

      expect(cell.to_asciidoc).to eq("| [[cell-1]]Cell content")
    end

    it "combines all attributes" do
      anchor = instance_double(Coradoc::Model::Inline::Anchor,
        to_asciidoc: "[[cell-1]]"
      )

      cell = described_class.new(
        content: "Cell content",
        colrowattr: "2.3+",
        alignattr: "^",
        style: "a"
      )
      allow(cell).to receive(:anchor).and_return(anchor)

      expect(cell.to_asciidoc).to eq("2.3+^a| [[cell-1]]Cell content")
    end

    context "with text content" do
      it "processes through unicode stripping" do
        cell = described_class.new(content: "Cell content")
        expect(Coradoc).to receive(:strip_unicode).with("Cell content")
        cell.to_asciidoc
      end
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
