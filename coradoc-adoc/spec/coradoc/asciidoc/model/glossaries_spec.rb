require "spec_helper"

RSpec.describe Coradoc::AsciiDoc::Model::Glossaries do
  describe ".new" do
    it "initializes with items" do
      glossaries = described_class.new(items: ["term1", "term2"])
      expect(glossaries.items).to eq(["term1", "term2"])
    end

    it "initializes with default empty array for items" do
      glossaries = described_class.new
      expect(glossaries.items).to eq([])
    end
  end
end
