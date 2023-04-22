require "spec_helper"

RSpec.describe Coradoc::Document::Attribute do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      key = "test-key"
      value = "test-value"

      attribute = Coradoc::Document::Attribute.new(key, value)

      expect(attribute.key).to eq(key)
      expect(attribute.value).to eq(value)
    end
  end
end
