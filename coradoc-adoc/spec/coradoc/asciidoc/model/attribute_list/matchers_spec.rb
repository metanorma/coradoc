require "spec_helper"

RSpec.describe Coradoc::AsciiDoc::Model::AttributeList::Matchers do
  let(:dummy_class) do
    Class.new do
      extend Coradoc::AsciiDoc::Model::AttributeList::Matchers
    end
  end

  describe ".one" do
    it "creates a One matcher" do
      matcher = dummy_class.one("test", "other")
      expect(matcher).to be_a(Coradoc::AsciiDoc::Model::AttributeList::Matchers::One)
    end
  end

  describe ".many" do
    it "creates a Many matcher" do
      matcher = dummy_class.many("test", "other")
      expect(matcher).to be_a(Coradoc::AsciiDoc::Model::AttributeList::Matchers::Many)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::AttributeList::Matchers::One do
  describe "#===" do
    let(:matcher) { described_class.new("yes", "true", 1) }

    it "matches if any possibility matches" do
      expect(matcher === "yes").to be true
      expect(matcher === "true").to be true
      expect(matcher === 1).to be true
    end

    it "does not match if no possibility matches" do
      expect(matcher === "no").to be false
      expect(matcher === "false").to be false
      expect(matcher === 0).to be false
    end
    
    it "works with regex possibilities" do
      regex_matcher = described_class.new(/^test/, "other")
      expect(regex_matcher === "testing").to be true
      expect(regex_matcher === "other").to be true
      expect(regex_matcher === "foo").to be false
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::AttributeList::Matchers::Many do
  describe "#===" do
    let(:matcher) { described_class.new("red", "blue", "green") }

    it "matches if all values in an array match a possibility" do
      expect(matcher === ["red", "blue"]).to be true
      expect(matcher === ["green"]).to be true
    end

    it "does not match if any value in an array doesn't match" do
      expect(matcher === ["red", "yellow"]).to be false
    end

    it "splits string input by comma and matches" do
      expect(matcher === "red,blue").to be true
      expect(matcher === "green,red,blue").to be true
      expect(matcher === "red,yellow").to be false
    end

    it "returns false for non-string/non-array input" do
      expect(matcher === 1).to be false
      expect(matcher === nil).to be false
    end
  end
end
