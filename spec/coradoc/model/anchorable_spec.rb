# frozen_string_literal: true

RSpec.describe Coradoc::Model::Anchorable do
  let(:test_class) do
    Class.new do
      include Coradoc::Model::Anchorable
      attr_accessor :id, :anchor

      def initialize(id: nil, anchor: nil)
        @id = id
        @anchor = anchor
      end
    end
  end

  describe "#default_anchor" do
    let(:instance) { test_class.new }

    context "when anchor is set" do
      it "returns the existing anchor" do
        existing_anchor = instance_double(Coradoc::Model::Inline::Anchor)
        instance = test_class.new(anchor: existing_anchor)

        expect(instance.default_anchor).to eq(existing_anchor)
      end
    end

    context "when anchor is nil but id is present" do
      it "creates a new anchor with the id" do
        instance = test_class.new(id: "section-1")

        expect(instance.default_anchor).to be_a(Coradoc::Model::Inline::Anchor)
        expect(instance.default_anchor.id).to eq("section-1")
      end
    end

    context "when both anchor and id are nil" do
      it "returns nil" do
        expect(instance.default_anchor).to be_nil
      end
    end

    context "when anchor is nil and id is empty string" do
      it "creates anchor with empty string id" do
        instance = test_class.new(id: "")

        expect(instance.default_anchor).to be_a(Coradoc::Model::Inline::Anchor)
        expect(instance.default_anchor.id).to eq("")
      end
    end
  end

  describe "module inclusion" do
    let(:another_test_class) do
      Class.new do
        include Coradoc::Model::Anchorable
      end
    end

    it "adds default_anchor method to including class" do
      expect(another_test_class.new).to respond_to(:default_anchor)
    end

    it "allows multiple classes to include the module" do
      expect(test_class.new).to respond_to(:default_anchor)
      expect(another_test_class.new).to respond_to(:default_anchor)
    end
  end
end
