# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocMappingRule do
  describe ".initialize" do
    it "initializes with default values" do
      rule = described_class.new("title", to: :title)

      expect(rule.name).to eq("title")
      expect(rule.to).to eq(:title)
      expect(rule.render_nil).to be false
      expect(rule.render_default).to be false
      expect(rule.field_type).to eq(:attributes)
      expect(rule.custom_methods).to eq({})
      expect(rule.delegate).to be_nil
      expect(rule.transform).to eq({})
    end

    it "initializes with custom values" do
      transform = { from: :string, to: :integer }
      with = { method: :custom_method }

      rule = described_class.new(
        "count",
        to: :count,
        render_nil: true,
        render_default: true,
        with: with,
        delegate: :delegated_method,
        field_type: :content,
        transform: transform
      )

      expect(rule.name).to eq("count")
      expect(rule.to).to eq(:count)
      expect(rule.render_nil).to be true
      expect(rule.render_default).to be true
      expect(rule.field_type).to eq(:content)
      expect(rule.custom_methods).to eq(with)
      expect(rule.delegate).to eq(:delegated_method)
      expect(rule.transform).to eq(transform)
    end
  end

  describe "#content?" do
    it "returns true when field_type is :content" do
      rule = described_class.new("body", to: :body, field_type: :content)
      expect(rule.content?).to be true
    end

    it "returns false when field_type is :attributes" do
      rule = described_class.new("title", to: :title, field_type: :attributes)
      expect(rule.content?).to be false
    end
  end

  describe "#deep_dup" do
    let(:original_rule) do
      described_class.new(
        "title",
        to: :title,
        render_nil: true,
        with: { method: :custom_method },
        delegate: :delegated_method,
        field_type: :content,
        transform: { from: :string, to: :integer }
      )
    end

    it "creates a deep copy of the rule" do
      duped_rule = original_rule.deep_dup
      expect(Coradoc.is_deep_dup?(duped_rule, original_rule)).to be true
    end
  end
end
