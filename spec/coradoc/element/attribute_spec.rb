require "spec_helper"

RSpec.describe Coradoc::Element::Attribute do
  describe ".initialize" do
    it "initializes and exposes attributes" do
      key = "test-key"
      value = "test-value"

      attribute = Coradoc::Element::Attribute.new(key, value, line_break: "\n")

      expect(attribute.key).to eq(key)
      expect(attribute.value).to eq(value)
    end

    it "exposes comma separated values as an array" do
      key = "comma-separted-values"
      value = "html,pdf,xml, adoc"

      attribute = Coradoc::Element::Attribute.new(key, value)

      expect(attribute.key).to eq(key)
      expect(attribute.value).to eq(value.split(",").map(&:strip))
    end
  end
end
