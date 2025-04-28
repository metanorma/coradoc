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
      expect(rule.with).to eq({})
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
      expect(rule.with).to eq(with)
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

      expect(duped_rule).to be_a(described_class)
      expect(duped_rule.name).to eq(original_rule.name)
      expect(duped_rule.to).to eq(original_rule.to)
      expect(duped_rule.render_nil).to eq(original_rule.render_nil)
      expect(duped_rule.with).to eq(original_rule.with)
      expect(duped_rule.delegate).to eq(original_rule.delegate)
      expect(duped_rule.field_type).to eq(original_rule.field_type)
      expect(duped_rule.transform).to eq(original_rule.transform)

      # Verify it's a deep copy
      expect(duped_rule.name).not_to be(original_rule.name)
      expect(duped_rule.to).not_to be(original_rule.to)
      expect(duped_rule.with).not_to be(original_rule.with)
      expect(duped_rule.transform).not_to be(original_rule.transform)
    end
  end
end
