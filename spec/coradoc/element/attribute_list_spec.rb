require "spec_helper"

RSpec.describe Coradoc::Element::AttributeList do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      positional = ["a", "b", "c"]
      named = { 'd': "e", 'f': "g" }

      attribute_list = described_class.new("a", "b", "c", 'd': "e",
                                                          'f': "g")

      expect(attribute_list.positional).to eq(positional)
      expect(attribute_list.named).to eq(named)
    end

    it "validates attributes" do
      V_POS = [[:alt, String], [:width, Integer], [:broken, String]].freeze
      V_NAM = { alt: String, width: Integer, broken: String }.freeze
      attributes = described_class.new
      attributes.add_positional("Alt text")
      attributes.add_positional(256)
      attributes.add_positional(400)
      attributes.add_named(:alt, "Alt text")
      attributes.add_named(:width, 512)
      attributes.add_named(:broken, 600)
      attributes.validate_positional(V_POS)
      attributes.validate_named(V_NAM)
      expect(attributes.rejected_positional).to eq([[2, 400]])
      expect(attributes.rejected_named).to eq([[:broken, 600]])
    end

    it "supports one and many matchers" do
      correct = described_class.new(x1: "abc", x2: "def", x3: ["ghi", "jkl"])
      incorrect = described_class.new(x1: "Abc", x2: "Def", x3: 1)
      incorrect2 = described_class.new(x1: "ddd", x2: "ddd", x3: ["ghi", "mno"])

      extend Coradoc::Element::AttributeList::Matchers
      VALIDATOR = {
        x1: one("abc", /^d{3}$/),
        x2: one("def", /^d{3}$/),
        x3: many("ghi", "jkl"),
      }.freeze

      correct.validate_named(VALIDATOR)
      incorrect.validate_named(VALIDATOR)
      incorrect2.validate_named(VALIDATOR)

      expect(correct.rejected_named).to eq([])
      expect(incorrect.rejected_named).to eq([[:x1, "Abc"], [:x2, "Def"],
                                              [:x3, 1]])
      expect(incorrect2.rejected_named).to eq([[:x3, ["ghi", "mno"]]])
    end
  end
end
