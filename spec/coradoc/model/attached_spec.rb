require "spec_helper"

RSpec.describe Coradoc::Model::Attached do
  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "instance creation" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end

    it "accepts attributes from Base" do
      instance = described_class.new(id: "test-id")
      expect(instance.id).to eq("test-id")
    end
  end

  describe "functionality" do
    it "maintains Base class functionality" do
      instance = described_class.new
      expect(instance).to respond_to(:id)
      expect(instance).to be_a(Coradoc::Model::Base)
    end
  end
end
