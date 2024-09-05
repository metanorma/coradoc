require "spec_helper"

RSpec.describe Coradoc::Element::Tag do
  describe ".initialize" do
    it "initializes and exposes tag" do
      name = "name"
      opts = {prefix: "tag",
        attribute_list: Coradoc::Element::AttributeList.new,
        line_break: "\n"}
      tag = Coradoc::Element::Tag.new(name, opts)
      expect(tag.name).to eq(name)
      expect(tag.prefix).to eq("tag")
      expect(tag.attrs.class).to eq(Coradoc::Element::AttributeList)
      expect(tag.line_break).to eq("\n")
    end
  end
end
