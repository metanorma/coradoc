require "spec_helper"

RSpec.describe Coradoc::Element::AttributeList do
  describe ".initialize" do
    it "initializes and exposes attributes" do

      positional = ['a','b','c']
      named = {'d':'e','f':'g'}

      attribute_list = Coradoc::Element::AttributeList.new('a','b','c','d':'e','f':'g')

      expect(attribute_list.positional).to eq(positional)
      expect(attribute_list.named).to eq(named)
    end
  end
end
