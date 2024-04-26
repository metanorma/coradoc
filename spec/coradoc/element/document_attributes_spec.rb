require "spec_helper"

RSpec.describe Coradoc::Element::DocumentAttributes do
  describe ".initialize" do
    it "initializes and exposes document_attributes" do
      data = [Coradoc::Element::Attribute.new("name", "value")]
      document_attributes = Coradoc::Element::DocumentAttributes.new(data)

      expect(document_attributes.data).to eq(data)
    end
  end
end
