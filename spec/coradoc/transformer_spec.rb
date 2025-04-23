require "spec_helper"

RSpec.describe Coradoc::Transformer do
  describe ".transform" do
    it "transforms the abstract syntax tree to document" do
      file = Coradoc.root_path.join("spec", "fixtures", "sample-oscal.adoc")
      syntax_tree = Coradoc::Parser.parse(file)
      doc = described_class.transform(syntax_tree)

      expect(doc.header.class).to eq(Coradoc::Model::Header)
      expect(doc.document_attributes.class).to eq(Coradoc::Model::DocumentAttributes)
      expect(doc.document_attributes.data[0].class).to eq(Coradoc::Model::Attribute)

      section = doc.sections.first
      expect(section.sections.count).to eq(14)
      expect(section.sections.first.sections.count).to eq(4)
      expect(section.class).to eq(Coradoc::Model::Section)
      expect(section.title.class).to eq(Coradoc::Model::Title)
      expect(section.sections.first.class).to eq(Coradoc::Model::Section)
      expect(section.sections.first.sections.first.title.text).to eq("Control")
    end
  end
end
