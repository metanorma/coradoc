require "spec_helper"

RSpec.describe Coradoc::AsciiDoc::Model::RejectedPositionalAttribute do
  describe ".new" do
    it "initializes with position and value" do
      attr = described_class.new(position: 1, value: "test")
      expect(attr.position).to eq(1)
      expect(attr.value).to eq("test")
    end

    it "initializes with defaults" do
      attr = described_class.new
      expect(attr.position).to be_nil
      expect(attr.value).to be_nil
    end
  end
end
