require "spec_helper"

RSpec.describe Coradoc::Model::Inline::AttributeReference do
  describe ".initialize" do
    it "initializes with name" do
      ref = described_class.new(name: "version")
      expect(ref.name).to eq("version")
    end

    it "initializes with no attributes" do
      ref = described_class.new
      expect(ref.name).to be_nil
    end
  end

  describe "#to_asciidoc" do
    it "generates basic attribute reference" do
      ref = described_class.new(name: "version")
      expect(ref.to_asciidoc).to eq("{version}")
    end

    it "handles empty name" do
      ref = described_class.new(name: "")
      expect(ref.to_asciidoc).to eq("{}")
    end

    it "handles nil name" do
      ref = described_class.new
      expect(ref.to_asciidoc).to eq("{}")
    end

    it "preserves special characters in name" do
      ref = described_class.new(name: "app-version")
      expect(ref.to_asciidoc).to eq("{app-version}")
    end

    it "handles name with dots" do
      ref = described_class.new(name: "company.name")
      expect(ref.to_asciidoc).to eq("{company.name}")
    end

    it "handles name with underscores" do
      ref = described_class.new(name: "project_version")
      expect(ref.to_asciidoc).to eq("{project_version}")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "usage examples" do
    it "works for version references" do
      ref = described_class.new(name: "version")
      expect("Current version: #{ref.to_asciidoc}").to eq("Current version: {version}")
    end

    it "works for author references" do
      ref = described_class.new(name: "author")
      expect("By #{ref.to_asciidoc}").to eq("By {author}")
    end

    it "works for date references" do
      ref = described_class.new(name: "revdate")
      expect("Last updated: #{ref.to_asciidoc}").to eq("Last updated: {revdate}")
    end

    it "works for custom attributes" do
      ref = described_class.new(name: "custom-value")
      expect("Value: #{ref.to_asciidoc}").to eq("Value: {custom-value}")
    end
  end

  describe "common attribute names" do
    %w[author email revnumber revdate].each do |attr|
      it "handles #{attr} attribute" do
        ref = described_class.new(name: attr)
        expect(ref.to_asciidoc).to eq("{#{attr}}")
      end
    end
  end
end
