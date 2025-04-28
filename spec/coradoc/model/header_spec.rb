require "spec_helper"

RSpec.describe Coradoc::Model::Header do
  let(:author) { instance_double(Coradoc::Model::Author) }
  let(:revision) { instance_double(Coradoc::Model::Revision) }

  describe ".initialize" do
    it "initializes with full attributes" do
      header = described_class.new(
        title: "Document Title",
        author: author,
        revision: revision
      )

      expect(header.title).to eq("Document Title")
      expect(header.author).to eq(author)
      expect(header.revision).to eq(revision)
    end

    it "accepts title only" do
      header = described_class.new(title: "Document Title")

      expect(header.title).to eq("Document Title")
      expect(header.author).to be_nil
      expect(header.revision).to be_nil
    end

    it "initializes with no attributes" do
      header = described_class.new

      expect(header.title).to be_nil
      expect(header.author).to be_nil
      expect(header.revision).to be_nil
    end
  end

  describe "#to_asciidoc" do
    context "with full header" do
      before do
        allow(author).to receive(:to_asciidoc).and_return("John Doe <john@example.com>\n")
        allow(revision).to receive(:to_asciidoc).and_return("v1.0, 2024-01-01\n")
      end

      it "generates complete header" do
        header = described_class.new(
          title: "Document Title",
          author: author,
          revision: revision
        )

        expected_output = "= Document Title\nJohn Doe <john@example.com>\nv1.0, 2024-01-01\n"
        expect(header.to_asciidoc).to eq(expected_output)
      end
    end

    context "with partial header" do
      it "generates header with title only" do
        header = described_class.new(title: "Document Title")
        expect(header.to_asciidoc).to eq("= Document Title\n")
      end

      it "generates header with title and author" do
        allow(author).to receive(:to_asciidoc).and_return("John Doe <john@example.com>\n")

        header = described_class.new(
          title: "Document Title",
          author: author
        )

        expect(header.to_asciidoc).to eq("= Document Title\nJohn Doe <john@example.com>\n")
      end

      it "generates header with title and revision" do
        allow(revision).to receive(:to_asciidoc).and_return("v1.0, 2024-01-01\n")

        header = described_class.new(
          title: "Document Title",
          revision: revision
        )

        expect(header.to_asciidoc).to eq("= Document Title\nv1.0, 2024-01-01\n")
      end
    end

    it "handles empty title" do
      header = described_class.new(title: "")
      expect(header.to_asciidoc).to eq("= \n")
    end

    it "handles nil title" do
      header = described_class.new
      expect(header.to_asciidoc).to eq("= \n")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "asciidoc mapping" do
    it "maps all attributes correctly" do
      mapping = described_class.asciidoc_mapping.mappings
      mapped_attributes = mapping.map { |m| m.instance_variable_get(:@to) }

      expect(mapped_attributes).to include(:title, :author, :revision)
    end
  end

  describe "attribute types" do
    it "validates author type" do
      expect { described_class.new(title: "Title", author: "Invalid Author") }
        .to raise_error(TypeError)
    end

    it "validates revision type" do
      expect { described_class.new(title: "Title", revision: "Invalid Revision") }
        .to raise_error(TypeError)
    end
  end
end
