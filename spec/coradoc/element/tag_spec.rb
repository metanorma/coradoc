require "spec_helper"

RSpec.describe Coradoc::Element::Tag do
  describe ".initialize" do
    it "initializes and exposes tag" do
      name = "name"
      opts = { prefix: "tag",
               attribute_list: Coradoc::Element::AttributeList.new(**{}),
               line_break: "\n" }
      tag = described_class.new(name:, prefix: opts[:prefix],
                                attrs: opts[:attribute_list], line_break: opts[:line_break])
      expect(tag.name).to eq(name)
      expect(tag.prefix).to eq("tag")
      expect(tag.attrs.class).to eq(Coradoc::Element::AttributeList)
      expect(tag.line_break).to eq("\n")
    end
  end
end
