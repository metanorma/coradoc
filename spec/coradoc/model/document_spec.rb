# frozen_string_literal: true

RSpec.describe Coradoc::Model::Document do
  describe ".initialize" do
    it "initializes with default values" do
      document = described_class.new

      expect(document.document_attributes).to be_a(Coradoc::Model::DocumentAttributes)
      expect(document.header).to be_a(Coradoc::Model::Header)
      expect(document.header.title).to eq("")
      expect(document.sections).to eq([])
    end

    it "accepts custom values" do
      document_attributes = Coradoc::Model::DocumentAttributes.new
      header = Coradoc::Model::Header.new(title: "Test Document")
      sections = [
        instance_double(Coradoc::Model::Section),
        instance_double(Coradoc::Model::Section)
      ]

      document = described_class.new(
        document_attributes: document_attributes,
        header: header,
        sections: sections
      )

      expect(document.document_attributes).to eq(document_attributes)
      expect(document.header).to eq(header)
      expect(document.sections).to eq(sections)
    end
  end

  describe "#to_asciidoc" do
    let(:document_attributes) { instance_double(Coradoc::Model::DocumentAttributes) }
    let(:header) { instance_double(Coradoc::Model::Header) }
    let(:sections) { [instance_double(Coradoc::Model::Section)] }
    let(:document) do
      described_class.new(
        document_attributes: document_attributes,
        header: header,
        sections: sections
      )
    end

    before do
      allow(Coradoc::Generator).to receive(:gen_adoc).with(header).and_return("= Test Document\n\n")
      allow(Coradoc::Generator).to receive(:gen_adoc).with(document_attributes).and_return(":attr: value\n\n")
      allow(Coradoc::Generator).to receive(:gen_adoc).with(sections).and_return("== Section 1\n\nContent\n")
    end

    it "generates complete document" do
      expected_output = "= Test Document\n\n:attr: value\n\n== Section 1\n\nContent\n"
      expect(document.to_asciidoc).to eq(expected_output)
    end

    it "uses Generator.gen_adoc for each component" do
      expect(Coradoc::Generator).to receive(:gen_adoc).with(header)
      expect(Coradoc::Generator).to receive(:gen_adoc).with(document_attributes)
      expect(Coradoc::Generator).to receive(:gen_adoc).with(sections)

      document.to_asciidoc
    end
  end

  describe ".from_ast" do
    let(:document_attributes) { instance_double(Coradoc::Model::DocumentAttributes) }
    let(:header) { instance_double(Coradoc::Model::Header) }
    let(:section1) { instance_double(Coradoc::Model::Section) }
    let(:section2) { instance_double(Coradoc::Model::Section) }

    let(:elements) { [document_attributes, header, section1, section2] }

    it "creates document from AST elements" do
      document = described_class.from_ast(elements)

      expect(document.document_attributes).to eq(document_attributes)
      expect(document.header).to eq(header)
      expect(document.sections).to eq([section1, section2])
    end

    it "handles missing document attributes" do
      document = described_class.from_ast([header, section1])

      expect(document.document_attributes).to be_nil
      expect(document.header).to eq(header)
      expect(document.sections).to eq([section1])
    end

    it "handles missing header" do
      document = described_class.from_ast([document_attributes, section1])

      expect(document.document_attributes).to eq(document_attributes)
      expect(document.header).to be_nil
      expect(document.sections).to eq([section1])
    end

    it "handles empty sections" do
      document = described_class.from_ast([document_attributes, header])

      expect(document.document_attributes).to eq(document_attributes)
      expect(document.header).to eq(header)
      expect(document.sections).to eq([])
    end

    it "ignores unknown elements" do
      unknown_element = double("UnknownElement")
      document = described_class.from_ast([document_attributes, unknown_element, header, section1])

      expect(document.document_attributes).to eq(document_attributes)
      expect(document.header).to eq(header)
      expect(document.sections).to eq([section1])
    end
  end
end
