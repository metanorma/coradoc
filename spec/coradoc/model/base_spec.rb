require "spec_helper"

RSpec.describe Coradoc::Model::Base do
  describe ".initialize" do
    it "initializes and exposes the id attribute" do
      id = "test-123"
      instance = described_class.new(id: id)

      expect(instance.id).to eq(id)
    end

    it "allows initialization without an id" do
      instance = described_class.new

      expect(instance.id).to be_nil
    end
  end
end
