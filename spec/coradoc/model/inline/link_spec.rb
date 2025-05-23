# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Link do
  describe ".initialize" do
    it "initializes with basic attributes" do
      link = described_class.new(
        path: "https://example.com",
        title: "Example Site",
        name: "Example"
      )

      expect(link.path).to eq("https://example.com")
      expect(link.title).to eq("Example Site")
      expect(link.name).to eq("Example")
      expect(link.right_constrain).to be false
    end

    it "accepts right_constrain parameter" do
      link = described_class.new(
        path: "document.pdf",
        right_constrain: true
      )

      expect(link.right_constrain).to be true
    end

    it "uses default values" do
      link = described_class.new

      expect(link.path).to be_nil
      expect(link.title).to be_nil
      expect(link.name).to be_nil
      expect(link.right_constrain).to be false
    end
  end

  describe "#to_asciidoc" do
    context "with URL paths" do
      it "generates link with name" do
        link = described_class.new(
          path: "https://example.com",
          name: "Example"
        )

        expect(link.to_asciidoc).to eq("https://example.com[Example]")
      end

      it "generates link with title" do
        link = described_class.new(
          path: "https://example.com",
          title: "Example Site"
        )

        expect(link.to_asciidoc).to eq("https://example.com[Example Site]")
      end

      it "generates bare URL when no name or title" do
        link = described_class.new(
          path: "https://example.com"
        )

        expect(link.to_asciidoc).to eq("https://example.com")
      end

      it "forces brackets with right_constrain" do
        link = described_class.new(
          path: "https://example.com",
          right_constrain: true
        )

        expect(link.to_asciidoc).to eq("https://example.com[]")
      end
    end

    context "with non-URL paths" do
      it "prefixes with link:" do
        link = described_class.new(
          path: "document.pdf",
          name: "Document"
        )

        expect(link.to_asciidoc).to eq("link:document.pdf[Document]")
      end

      it "adds empty brackets when no name or title" do
        link = described_class.new(
          path: "document.pdf"
        )

        expect(link.to_asciidoc).to eq("link:document.pdf[]")
      end
    end

    it "prioritizes name over title" do
      link = described_class.new(
        path: "https://example.com",
        name: "Example",
        title: "Example Site"
      )

      expect(link.to_asciidoc).to eq("https://example.com[Example]")
    end

    it "handles empty name and title" do
      link = described_class.new(
        path: "document.pdf",
        name: "",
        title: ""
      )

      expect(link.to_asciidoc).to eq("link:document.pdf[]")
    end

    it "preserves query parameters in URLs" do
      link = described_class.new(
        path: "https://example.com/search?q=test&page=1",
        name: "Search"
      )

      expect(link.to_asciidoc).to eq("https://example.com/search?q=test&page=1[Search]")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
