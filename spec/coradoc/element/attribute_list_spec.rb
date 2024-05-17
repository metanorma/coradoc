require "spec_helper"

RSpec.describe Coradoc::Element::AttributeList do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      positional = ["a", "b", "c"]
      named = { 'd': "e", 'f': "g" }

      attribute_list = Coradoc::Element::AttributeList.new("a", "b", "c", 'd': "e",
                                                                          'f': "g")

      expect(attribute_list.positional).to eq(positional)
      expect(attribute_list.named).to eq(named)
    end

    it "validates attributes" do
      V_POS = [ [:alt, String], [:width, Integer], [:broken, String]]
      V_NAM = {alt: String, width: Integer, broken: String}
      attributes = Coradoc::Element::AttributeList.new
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
  end
end
