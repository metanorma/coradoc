# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocMapping do
  let(:mapping) { described_class.new }

  describe "#initialize" do
    it "initializes with empty mappings" do
      expect(mapping.mappings).to be_empty
    end
  end

  describe "#map_content" do
    it "adds a content mapping rule" do
      mapping.map_content(to: :body)

      rule = mapping.mappings.first
      expect(rule).to be_a(Coradoc::Model::Serialization::AsciidocMappingRule)
      expect(rule.name).to eq("__content")
      expect(rule.to).to eq(:body)
      expect(rule.field_type).to eq(:content)
    end
  end

  describe "#map_attribute" do
    it "adds an attribute mapping rule" do
      mapping.map_attribute("title", to: :title)

      rule = mapping.mappings.first
      expect(rule).to be_a(Coradoc::Model::Serialization::AsciidocMappingRule)
      expect(rule.name).to eq("title")
      expect(rule.to).to eq(:title)
      expect(rule.field_type).to eq(:attributes)
    end

    it "supports render_nil option" do
      mapping.map_attribute("author", to: :author, render_nil: true)

      rule = mapping.mappings.first
      expect(rule.render_nil).to be true
    end

    it "allows multiple attribute mappings" do
      mapping.map_attribute("title", to: :title)
      mapping.map_attribute("author", to: :author)
      mapping.map_attribute("date", to: :date)

      expect(mapping.mappings.length).to eq(3)
      expect(mapping.mappings.map(&:name)).to eq(["title", "author", "date"])
      expect(mapping.mappings.map(&:to)).to eq([:title, :author, :date])
    end
  end

  describe "mapping combinations" do
    it "supports both content and attribute mappings" do
      mapping.map_content(to: :body)
      mapping.map_attribute("title", to: :title)
      mapping.map_attribute("author", to: :author)

      expect(mapping.mappings.length).to eq(3)
      expect(mapping.mappings.map(&:field_type))
        .to eq([:content, :attributes, :attributes])
    end
  end
end
