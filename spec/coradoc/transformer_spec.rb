require "spec_helper"

RSpec.describe Coradoc::Transformer do
  describe ".transform" do
    it "transforms the abstract syntax tree to document" do
      file = Coradoc.root_path.join("spec", "fixtures", "sample-oscal.adoc")
      syntax_tree = Coradoc::Parser.parse(file)
      doc = Coradoc::Transformer.transform(syntax_tree)

      expect(doc.header.class).to eq(Coradoc::Element::Header)
      expect(doc.document_attributes.class).to eq(Coradoc::Element::DocumentAttributes)
      expect(doc.document_attributes.data[0].class).to eq(Coradoc::Element::Attribute)

      section = doc.sections.first
      expect(section.sections.count).to eq(14)
      expect(section.sections.first.sections.count).to eq(4)
      expect(section.class).to eq(Coradoc::Element::Section)
      expect(section.title.class).to eq(Coradoc::Element::Title)
      expect(section.sections.first.class).to eq(Coradoc::Element::Section)
      expect(section.sections.first.sections.first.title.text).to eq("Control")
    end
  end
end

