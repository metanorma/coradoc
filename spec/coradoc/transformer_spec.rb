require "spec_helper"

RSpec.describe Coradoc::Transformer do
  describe ".transform" do
    it "transforms the abstract syntax tree to document" do
      file = Coradoc.root_path.join("spec", "fixtures", "sample-oscal.adoc")
      syntax_tree = Coradoc::Parser.parse(file)
      doc = Coradoc::Transformer.transform(syntax_tree)[:document]

      expect(doc[0][:header].class).to eq(Coradoc::Document::Header)
      expect(doc[1][:bibdata].class).to eq(Coradoc::Document::Bibdata)
      expect(doc[1][:bibdata].data[0].class).to eq(Coradoc::Document::Attribute)

      section = doc[3][:section]
      expect(section.sections.count).to eq(14)
      expect(section.class).to eq(Coradoc::Document::Section)
      expect(section.title.class).to eq(Coradoc::Document::Title)
      expect(section.sections.first.class).to eq(Coradoc::Document::Section)
    end
  end
end

