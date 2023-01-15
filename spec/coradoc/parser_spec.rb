require "spec_helper"

RSpec.describe Coradoc::Parser do
  describe ".parse" do
    it "parses the document to metanorma document" do
      sample_file = Coradoc.root_path.join(
        "spec", "fixtures", "iso-sample", "rice-en.cd.sections.adoc",
      )

      document = Coradoc::Parser.parse(sample_file.to_s)

      expect(document.class).to be(Coradoc::Document::Base)
      expect(document.bibdata.class).to be(Coradoc::Document::BibData)
      expect(document.bibdata.docnumber).to eq("173012")
    end
  end
end
