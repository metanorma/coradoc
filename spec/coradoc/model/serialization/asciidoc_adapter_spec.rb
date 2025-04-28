# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocAdapter do
  let(:sections) { [double("Section1", to_asciidoc: "Section 1"), double("Section2", to_asciidoc: "Section 2")] }
  let(:adapter) { described_class.new(sections) }

  describe "inheritance" do
    it "inherits from AsciidocDocument" do
      expect(described_class.superclass).to eq(Coradoc::Model::Serialization::AsciidocDocument)
    end
  end

  describe "document functionality" do
    it "maintains AsciidocDocument behavior" do
      expect(adapter.sections).to eq(sections)
      expect(adapter.to_asciidoc).to eq("Section 1\n\nSection 2")
      expect(adapter[0]).to eq(sections[0])
      expect(adapter.to_h).to eq(sections)
    end
  end

  describe ".parse" do
    let(:asciidoc_data) { "Some asciidoc content" }
    let(:parsed_data) { { document: sections } }
    let(:parser) { instance_double(Coradoc::Parser::Base, parse: parsed_data) }

    before do
      allow(Coradoc::Parser::Base).to receive(:new).with(asciidoc_data).and_return(parser)
    end

    it "creates an adapter instance with parsed sections" do
      result = described_class.parse(asciidoc_data)
      expect(result).to be_a(described_class)
      expect(result.sections).to eq(sections)
    end
  end
end
