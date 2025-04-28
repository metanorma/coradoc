require "spec_helper"

RSpec.describe Coradoc::Model::Serialization do
  describe "AsciidocError" do
    it "inherits from StandardError" do
      expect(described_class::AsciidocError.superclass).to eq(StandardError)
    end
  end

  describe "ParseError" do
    it "initializes with message only" do
      error = described_class::ParseError.new("Invalid syntax")

      expect(error.message).to eq("Invalid syntax")
      expect(error.input).to be_nil
      expect(error.line_number).to be_nil
    end

    it "initializes with all attributes" do
      error = described_class::ParseError.new(
        "Invalid syntax",
        input: "== Bad Header",
        line_number: 42
      )

      expect(error.message).to eq("Invalid syntax")
      expect(error.input).to eq("== Bad Header")
      expect(error.line_number).to eq(42)
    end

    it "inherits from AsciidocError" do
      expect(described_class::ParseError.superclass).to eq(described_class::AsciidocError)
    end
  end

  describe "MappingError" do
    it "initializes with message only" do
      error = described_class::MappingError.new("Invalid mapping")

      expect(error.message).to eq("Invalid mapping")
      expect(error.field_name).to be_nil
      expect(error.value).to be_nil
    end

    it "initializes with all attributes" do
      error = described_class::MappingError.new(
        "Invalid mapping",
        field_name: "title",
        value: 123
      )

      expect(error.message).to eq("Invalid mapping")
      expect(error.field_name).to eq("title")
      expect(error.value).to eq(123)
    end

    it "inherits from AsciidocError" do
      expect(described_class::MappingError.superclass).to eq(described_class::AsciidocError)
    end
  end

  describe "ValidationError" do
    it "initializes with message only" do
      error = described_class::ValidationError.new("Validation failed")

      expect(error.message).to eq("Validation failed")
      expect(error.field_name).to be_nil
    end

    it "initializes with all attributes" do
      error = described_class::ValidationError.new(
        "Required field missing",
        field_name: "title"
      )

      expect(error.message).to eq("Required field missing")
      expect(error.field_name).to eq("title")
    end

    it "inherits from AsciidocError" do
      expect(described_class::ValidationError.superclass).to eq(described_class::AsciidocError)
    end
  end

  describe "SerializationError" do
    it "initializes with message only" do
      error = described_class::SerializationError.new("Serialization failed")

      expect(error.message).to eq("Serialization failed")
      expect(error.object).to be_nil
    end

    it "initializes with all attributes" do
      object = double("Document")
      error = described_class::SerializationError.new(
        "Invalid document state",
        object: object
      )

      expect(error.message).to eq("Invalid document state")
      expect(error.object).to eq(object)
    end

    it "inherits from AsciidocError" do
      expect(described_class::SerializationError.superclass).to eq(described_class::AsciidocError)
    end
  end

  describe "error hierarchy" do
    let(:base_error) { described_class::AsciidocError }
    let(:specific_errors) do
      [
        described_class::ParseError,
        described_class::MappingError,
        described_class::ValidationError,
        described_class::SerializationError
      ]
    end

    it "ensures all errors inherit from AsciidocError" do
      specific_errors.each do |error_class|
        expect(error_class.superclass).to eq(base_error)
      end
    end

    it "allows catching all errors as AsciidocError" do
      specific_errors.each do |error_class|
        expect { raise error_class, "Test error" }.to raise_error(base_error)
      end
    end
  end
end
