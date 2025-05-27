# frozen_string_literal: true

RSpec.describe Coradoc::Model::Author do
  describe ".initialize" do
    it "initializes with full details" do
      author = described_class.new(
        first_name: "John",
        middle_name: "William",
        last_name: "Doe",
        email: "john.doe@example.com",
      )

      expect(author.first_name).to eq("John")
      expect(author.middle_name).to eq("William")
      expect(author.last_name).to eq("Doe")
      expect(author.email).to eq("john.doe@example.com")
    end

    it "accepts partial details" do
      author = described_class.new(first_name: "John", last_name: "Doe")

      expect(author.first_name).to eq("John")
      expect(author.last_name).to eq("Doe")
      expect(author.middle_name).to be_nil
      expect(author.email).to be_nil
    end

    it "allows initialization with no arguments" do
      author = described_class.new

      expect(author.first_name).to be_nil
      expect(author.middle_name).to be_nil
      expect(author.last_name).to be_nil
      expect(author.email).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "formats full name with email" do
      author = described_class.new(
        first_name: "John",
        middle_name: "William",
        last_name: "Doe",
        email: "john.doe@example.com",
      )

      expect(author.to_asciidoc).to eq("John William Doe <john.doe@example.com>\n")
    end

    it "formats name without middle name" do
      author = described_class.new(
        first_name: "John",
        last_name: "Doe",
        email: "john.doe@example.com",
      )

      expect(author.to_asciidoc).to eq("John Doe <john.doe@example.com>\n")
    end

    it "formats name without email" do
      author = described_class.new(
        first_name: "John",
        middle_name: "William",
        last_name: "Doe",
      )

      expect(author.to_asciidoc).to eq("John William Doe")
    end

    it "formats first and last name only" do
      author = described_class.new(first_name: "John", last_name: "Doe")

      expect(author.to_asciidoc).to eq("John Doe")
    end

    it "handles missing first name" do
      author = described_class.new(last_name: "Doe", email: "doe@example.com")

      expect(author.to_asciidoc).to eq("Doe <doe@example.com>\n")
    end

    it "handles missing last name" do
      author = described_class.new(
        first_name: "John",
        email: "john@example.com",
      )

      expect(author.to_asciidoc).to eq("John <john@example.com>\n")
    end

    it "handles email only" do
      author = described_class.new(email: "anonymous@example.com")

      expect(author.to_asciidoc).to eq(" <anonymous@example.com>\n")
    end
  end
end
