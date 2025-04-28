require "spec_helper"

RSpec.describe Coradoc::Model::Tag do
  describe ".initialize" do
    it "initializes with name" do
      tag = described_class.new(name: "test-tag")

      expect(tag.name).to eq("test-tag")
      expect(tag.prefix).to eq("tag")
      expect(tag.attrs).to be_a(Coradoc::Model::AttributeList)
      expect(tag.line_break).to eq("\n")
    end

    it "uses default values when not provided" do
      tag = described_class.new

      expect(tag.prefix).to eq("tag")
      expect(tag.attrs).to be_a(Coradoc::Model::AttributeList)
      expect(tag.line_break).to eq("\n")
    end

    it "accepts custom prefix" do
      tag = described_class.new(
        name: "test-tag",
        prefix: "custom"
      )

      expect(tag.name).to eq("test-tag")
      expect(tag.prefix).to eq("custom")
    end

    it "accepts custom attributes" do
      attrs = Coradoc::Model::AttributeList.new
      tag = described_class.new(
        name: "test-tag",
        attrs: attrs
      )

      expect(tag.attrs).to eq(attrs)
    end

    it "accepts custom line break" do
      tag = described_class.new(
        name: "test-tag",
        line_break: "\n\n"
      )

      expect(tag.line_break).to eq("\n\n")
    end
  end

  describe "#to_asciidoc" do
    it "generates basic tag without attributes" do
      tag = described_class.new(name: "test-tag")
      expect(tag.to_asciidoc).to eq("// tag::test-tag[]\n")
    end

    it "includes attributes when present" do
      attrs = instance_double(Coradoc::Model::AttributeList)
      allow(attrs).to receive(:to_asciidoc).and_return('[role="important"]')

      tag = described_class.new(
        name: "test-tag",
        attrs: attrs
      )

      expect(tag.to_asciidoc).to eq('// tag::test-tag[role="important"]\n')
    end

    it "uses custom prefix" do
      tag = described_class.new(
        name: "test-tag",
        prefix: "custom"
      )

      expect(tag.to_asciidoc).to eq("// custom::test-tag[]\n")
    end

    it "uses custom line break" do
      tag = described_class.new(
        name: "test-tag",
        line_break: "\n\n"
      )

      expect(tag.to_asciidoc).to eq("// tag::test-tag[]\n\n")
    end
  end
end
