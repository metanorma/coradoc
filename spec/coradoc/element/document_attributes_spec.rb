require "spec_helper"

RSpec.describe Coradoc::Element::DocumentAttributes do
  describe ".initialize" do
    it "initializes and exposes document_attributes" do
      data = [Coradoc::Element::Attribute.new(key: "name", value: "value")]
      document_attributes = described_class.new(data:)

      expect(document_attributes.data).to eq(data)
    end
  end
end
