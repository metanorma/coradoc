require "spec_helper"

RSpec.describe Coradoc::Model::Paragraph do
  describe ".initialize" do
    it "initializes with basic attributes" do
      paragraph = described_class.new(
        id: "para-1",
        content: "Sample content",
        title: "Sample Title"
      )

      expect(paragraph.id).to eq("para-1")
      expect(paragraph.content).to eq("Sample content")
      expect(paragraph.title).to eq("Sample Title")
      expect(paragraph.attrs).to be_a(Coradoc::Model::AttributeList)
      expect(paragraph.tdsinglepara).to be false
    end

    it "uses default values when not provided" do
      paragraph = described_class.new

      expect(paragraph.attrs).to be_a(Coradoc::Model::AttributeList)
      expect(paragraph.attrs).to be_empty
      expect(paragraph.tdsinglepara).to be false
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
      allow(Coradoc).to receive(:strip_unicode) { |content| content }
    end

    context "with tdsinglepara false (default)" do
      it "generates complete paragraph" do
        paragraph = described_class.new(
          title: "Sample Title",
          content: "Sample content"
        )

        expected_output = "\n\n.Sample Title\nSample content\n\n"
        expect(paragraph.to_asciidoc).to eq(expected_output)
      end

      it "includes anchor when present" do
        anchor = instance_double(Coradoc::Model::Inline::Anchor,
          to_adoc: "[[para-1]]"
        )

        paragraph = described_class.new(
          title: "Sample Title",
          content: "Sample content"
        )
        allow(paragraph).to receive(:anchor).and_return(anchor)

        expected_output = "\n\n.Sample Title\n[[para-1]]\nSample content\n\n"
        expect(paragraph.to_asciidoc).to eq(expected_output)
      end

      it "includes attributes when present" do
        attributes = instance_double(Coradoc::Model::AttributeList,
          to_adoc: "[.lead]"
        )

        paragraph = described_class.new(
          content: "Sample content",
          attributes: attributes
        )

        expected_output = "\n\n[.lead]\nSample content\n\n"
        expect(paragraph.to_asciidoc).to eq(expected_output)
      end
    end

    context "with tdsinglepara true" do
      it "generates paragraph without extra newlines" do
        paragraph = described_class.new(
          title: "Sample Title",
          content: "Sample content",
          tdsinglepara: true
        )

        expected_output = ".Sample Title\nSample content"
        expect(paragraph.to_asciidoc).to eq(expected_output)
      end

      it "includes anchor without extra newlines" do
        anchor = instance_double(Coradoc::Model::Inline::Anchor,
          to_adoc: "[[para-1]]"
        )

        paragraph = described_class.new(
          title: "Sample Title",
          content: "Sample content",
          tdsinglepara: true
        )
        allow(paragraph).to receive(:anchor).and_return(anchor)

        expected_output = ".Sample Title\n[[para-1]]\nSample content"
        expect(paragraph.to_asciidoc).to eq(expected_output)
      end
    end

    it "handles missing title" do
      paragraph = described_class.new(content: "Sample content")
      expect(paragraph.to_asciidoc).to eq("\n\nSample content\n\n")
    end

    it "handles empty content" do
      paragraph = described_class.new(title: "Sample Title")
      expect(paragraph.to_asciidoc).to eq("\n\n.Sample Title\n\n\n")
    end

    it "strips unicode from content" do
      paragraph = described_class.new(content: "Sample content")
      expect(Coradoc).to receive(:strip_unicode).with("Sample content")
      paragraph.to_asciidoc
    end
  end

  describe "inheritance and includes" do
    it "inherits from Attached" do
      expect(described_class.superclass).to eq(Coradoc::Model::Attached)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end


end
