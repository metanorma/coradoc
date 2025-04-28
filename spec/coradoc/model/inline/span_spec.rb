# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Span do
  let(:attributes) { instance_double(Coradoc::Model::AttributeList) }

  describe ".initialize" do
    it "initializes with all attributes" do
      span = described_class.new(
        text: "span text",
        role: "custom",
        attributes: attributes,
        unconstrainted: true
      )

      expect(span.text).to eq("span text")
      expect(span.role).to eq("custom")
      expect(span.attributes).to eq(attributes)
      expect(span.unconstrainted).to be true
    end

    it "uses default values" do
      span = described_class.new

      expect(span.text).to be_nil
      expect(span.role).to be_nil
      expect(span.attributes).to be_nil
      expect(span.unconstrainted).to be false
    end
  end

  describe "#to_asciidoc" do
    context "with attributes" do
      before do
        allow(attributes).to receive(:to_asciidoc).and_return("[opts=optional]")
      end

      it "generates span with attributes (unconstrained)" do
        span = described_class.new(
          text: "span text",
          attributes: attributes,
          unconstrainted: true
        )

        expect(span.to_asciidoc).to eq("[opts=optional]##span text##")
      end

      it "generates span with attributes (constrained)" do
        span = described_class.new(
          text: "span text",
          attributes: attributes
        )

        expect(span.to_asciidoc).to eq("[opts=optional]#span text#")
      end
    end

    context "with role" do
      it "generates span with role (unconstrained)" do
        span = described_class.new(
          text: "span text",
          role: "custom",
          unconstrainted: true
        )

        expect(span.to_asciidoc).to eq("[.custom]##span text##")
      end

      it "generates span with role (constrained)" do
        span = described_class.new(
          text: "span text",
          role: "custom"
        )

        expect(span.to_asciidoc).to eq("[.custom]#span text#")
      end
    end

    context "with neither attributes nor role" do
      it "returns plain text" do
        span = described_class.new(text: "span text")
        expect(span.to_asciidoc).to eq("span text")
      end

      it "converts nil text to empty string" do
        span = described_class.new
        expect(span.to_asciidoc).to eq("")
      end
    end

    it "prioritizes attributes over role" do
      allow(attributes).to receive(:to_asciidoc).and_return("[opts=optional]")

      span = described_class.new(
        text: "span text",
        attributes: attributes,
        role: "custom"
      )

      expect(span.to_asciidoc).to eq("[opts=optional]#span text#")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end

  describe "usage examples" do
    it "works for custom roles" do
      span = described_class.new(
        text: "special",
        role: "highlight"
      )
      expect("This is #{span.to_asciidoc}").to eq("This is [.highlight]#special#")
    end

    it "works with custom attributes" do
      allow(attributes).to receive(:to_asciidoc).and_return('[id="note1"]')

      span = described_class.new(
        text: "important note",
        attributes: attributes
      )
      expect(span.to_asciidoc).to eq('[id="note1"]#important note#')
    end

    it "works for plain text spans" do
      span = described_class.new(text: "normal text")
      expect("Before #{span.to_asciidoc} after").to eq("Before normal text after")
    end
  end
end
