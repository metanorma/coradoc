require "spec_helper"
require "coradoc/oscal"

RSpec.describe Coradoc::Oscal do
  describe ".parse" do
    xit "parses the document to proper document" do
      sample_file = Coradoc.root_path.join(
        "spec", "fixtures", "sample-oscal.adoc"
      )

      doc = Coradoc::Document.from_adoc(sample_file)
      oscal = Coradoc::Oscal.to_oscal(doc)

      expect(oscal["metadata"]["oscal-version"]).to eq("1.0.0")
      expect(oscal["groups"].first["controls"].count).to eq(14)
      expect(oscal["groups"].first["controls"].first["id"]).to eq("cls_5.1")
      expect(oscal["groups"].first["controls"].first["parts"].count).to eq(4)
    end
  end
end
