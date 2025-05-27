# frozen_string_literal: true

RSpec.describe Coradoc::Model::List::Nestable do
  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "as a base class" do
    let(:test_class) do
      Class.new(described_class) do
        attribute :test_attr, :string
      end
    end

    it "allows subclasses to define attributes" do
      instance = test_class.new(test_attr: "value")
      expect(instance.test_attr).to eq("value")
    end

    it "is used as parent for list implementations" do
      expect(Coradoc::Model::List::Core.superclass).to eq(described_class)
    end
  end

  describe "instance creation" do
    it "can be instantiated" do
      expect { described_class.new }
        .not_to raise_error
    end

    it "accepts attributes from Base" do
      instance = described_class.new(id: "test-id")
      expect(instance.id).to eq("test-id")
    end
  end

  describe "in list hierarchy" do
    it "serves as intermediate class between Base and Core" do
      hierarchy = [
        Coradoc::Model::List::Core.superclass,
        Coradoc::Model::List::Nestable.superclass,
      ]

      expect(hierarchy).to eq(
        [
          Coradoc::Model::List::Nestable,
          Coradoc::Model::Base,
        ],
      )
    end
  end
end
