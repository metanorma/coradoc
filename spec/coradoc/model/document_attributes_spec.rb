# frozen_string_literal: true

RSpec.describe Coradoc::Model::DocumentAttributes do
  let(:attribute1) do
    instance_double(Coradoc::Model::Attribute,
      key: "lang",
      value: "en",
      to_s: "en"
    )
  end

  let(:attribute2) do
    instance_double(Coradoc::Model::Attribute,
      key: "author",
      value: "John Doe",
      to_s: "John Doe"
    )
  end

  describe ".initialize" do
    it "initializes with attributes" do
      attributes = described_class.new(data: [attribute1, attribute2])
      expect(attributes.data).to eq([attribute1, attribute2])
    end

    it "initializes with empty data" do
      attributes = described_class.new
      expect(attributes.data).to be_nil
    end
  end

  describe "#to_hash" do
    let(:doc_attributes) { described_class.new(data: [attribute1, attribute2]) }

    it "converts attributes to hash" do
      allow(attribute1).to receive(:key) { "lang" }
      allow(attribute1).to receive(:value) { "en" }
      allow(attribute2).to receive(:key) { "author" }
      allow(attribute2).to receive(:value) { "John Doe" }

      result = doc_attributes.to_hash
      expect(result).to eq({
        "lang" => "en",
        "author" => "John Doe"
      })
    end

    it "removes single quotes from values" do
      allow(attribute1).to receive(:key) { "quote" }
      allow(attribute1).to receive(:value) { "'text'" }

      attributes = described_class.new(data: [attribute1])
      result = attributes.to_hash
      expect(result).to eq({ "quote" => "text" })
    end

    it "converts keys and values to strings" do
      allow(attribute1).to receive(:key) { :lang }
      allow(attribute1).to receive(:value) { :en }

      attributes = described_class.new(data: [attribute1])
      result = attributes.to_hash
      expect(result).to eq({ "lang" => "en" })
    end
  end

  describe "#to_asciidoc" do
    it "generates asciidoc for multiple attributes" do
      doc_attributes = described_class.new(data: [attribute1, attribute2])

      expected_output = ":lang: en\n:author: John Doe\n\n"
      expect(doc_attributes.to_asciidoc).to eq(expected_output)
    end

    it "handles empty values" do
      empty_attribute = instance_double(Coradoc::Model::Attribute,
        key: "empty",
        value: "",
        to_s: ""
      )

      doc_attributes = described_class.new(data: [empty_attribute])

      expected_output = ":empty:\n\n"
      expect(doc_attributes.to_asciidoc).to eq(expected_output)
    end

    it "handles no attributes" do
      doc_attributes = described_class.new

      expected_output = "\n"
      expect(doc_attributes.to_asciidoc).to eq(expected_output)
    end

    it "formats each attribute correctly" do
      single_attribute = instance_double(Coradoc::Model::Attribute,
        key: "test",
        value: "value",
        to_s: "value"
      )

      doc_attributes = described_class.new(data: [single_attribute])

      expected_output = ":test: value\n\n"
      expect(doc_attributes.to_asciidoc).to eq(expected_output)
    end
  end
end
