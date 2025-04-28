# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Anchor do
  describe ".initialize" do
    it "initializes with id" do
      anchor = described_class.new(id: "section-1")
      expect(anchor.id).to eq("section-1")
    end

    it "raises error without id" do
      result = described_class.new.validate
      expect(result).to include an_instance_of(Lutaml::Model::Error)
      expect(result).to include an_object_having_attributes(message: "ID cannot be nil or empty for Anchor")
    end

    it "raises error with empty id" do
      result = described_class.new(id: "").validate
      expect(result).to include an_instance_of(Lutaml::Model::Error)
      expect(result).to include an_object_having_attributes(message: "ID cannot be nil or empty for Anchor")
    end
  end

  describe "#validate" do
    it "returns errors when id is nil" do
      anchor = described_class.allocate  # Create instance without initialization
      allow(anchor).to receive(:id).and_return(nil)

      errors = anchor.send(:validate)
      expect(errors.first.message).to eq("ID cannot be nil or empty for Anchor")
    end

    it "returns errors when id is empty" do
      anchor = described_class.allocate
      allow(anchor).to receive(:id).and_return("")

      errors = anchor.send(:validate)
      expect(errors.first.message).to eq("ID cannot be nil or empty for Anchor")
    end

    it "returns no errors with valid id" do
      anchor = described_class.allocate
      allow(anchor).to receive(:id).and_return("valid-id")

      errors = anchor.send(:validate)
      expect(errors).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates anchor syntax" do
      anchor = described_class.new(id: "section-1")
      expect(anchor.to_asciidoc).to eq("[[section-1]]")
    end

    it "preserves special characters in id" do
      anchor = described_class.new(id: "section-1.2_3")
      expect(anchor.to_asciidoc).to eq("[[section-1.2_3]]")
    end

    it "handles numeric ids" do
      anchor = described_class.new(id: "123")
      expect(anchor.to_asciidoc).to eq("[[123]]")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
