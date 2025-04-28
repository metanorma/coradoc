# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocTransform do
  let(:model_class) do
    double("ModelClass").tap do |klass|
      allow(klass).to receive(:name).and_return("TestDocument")
      allow(klass).to receive(:entry_type).and_return("document")
      allow(klass).to receive(:content).and_return("content")
      allow(klass).to receive(:title).and_return("Test Document")
    end
  end

  let(:model) do
    double("Model").tap do |model|
      allow(model).to receive(:entry_type).and_return("document")
      allow(model).to receive(:content).and_return("content")
      allow(model).to receive(:title).and_return("Test Document")
      allow(model).to receive(:class).and_return(model_class)
    end
  end

  before do
    allow(model_class).to receive(:new).and_return(model)
  end

  let(:context) do
    double("Context").tap do |ctx|
      allow(ctx).to receive(:mappings_for).with(:asciidoc).and_return(mappings)
      allow(ctx).to receive(:attributes).and_return({ ' TODO' => 'attributes' })
      allow(ctx).to receive(:model).and_return(model_class)
    end
  end

  let(:mappings) do
    double("Mappings").tap do |mappings|
      allow(mappings).to receive(:mappings).and_return([
        double("Mapping",
          name: "title",
          to: "title",
          field_type: :attribute,
          entry_type?: false,
          content?: false
        )
      ])
    end
  end

  let(:transformer) { described_class.new(context) }

  describe ".data_to_model" do
    it "transforms asciidoc data to model" do
      data = double("Data").tap do |data|
        allow(data).to receive(:attributes).and_return({
          type: double("Entry",
            entry_type: "document",
            content: "content",
            attributes: { "title" => "Test Document" }
          )
        })
      end

      result = described_class.data_to_model(context, data, :asciidoc)
      expect(result).to be_an(Array)
    end
  end

  describe ".model_to_data" do
    it "transforms model to asciidoc data" do
      model = double("Model").tap do |model|
        allow(model).to receive(:entry_type).and_return("document")
        allow(model).to receive(:content).and_return("content")
        allow(model).to receive(:title).and_return("Test Document")
      end

      result = described_class.model_to_data(context, model, :asciidoc)

      expect(result).to be_a(Hash)
      expect(result[:entry_type]).to be_a(Coradoc::Model::Serialization::AsciidocDocumentEntry)
      expect(result[:entry_type].entry_type).to eq("document")
      expect(result[:entry_type].content).to eq("content")
    end

    it "handles collection attributes" do
      collection_mapping = double("Mapping",
        name: "items",
        to: "items",
        field_type: :attribute,
        entry_type?: false,
        content?: false
      )

      allow(mappings).to receive(:mappings).and_return([collection_mapping])

      items = [
        double("Item", to_adoc: "item1"),
        double("Item", to_adoc: "item2")
      ]

      model = double("Model").tap do |model|
        allow(model).to receive(:entry_type).and_return("list")
        allow(model).to receive(:content).and_return("")
        allow(model).to receive(:items).and_return(items)
      end

      result = described_class.model_to_data(context, model, :asciidoc)
      expect(result[:entry_type].attributes["items"]).to eq(["item1", "item2"])
    end
  end

  describe "#data_to_model" do
    it "skips nil field values" do
      data = double("Data").tap do |data|
        allow(data).to receive(:attributes).and_return({
          type: double("Entry",
            entry_type: "document",
            content: nil,
            attributes: { "title" => nil }
          )
        })
      end

      result = transformer.data_to_model(data)
      expect(result).to be_an(Array)
    end
  end

  describe "#model_to_data" do
    it "excludes non-attribute field types" do
      mapping = double("Mapping",
        name: "content",
        to: "content",
        field_type: :content,
        entry_type?: false,
        content?: true
      )

      allow(mappings).to receive(:mappings).and_return([mapping])

      model = double("Model").tap do |model|
        allow(model).to receive(:entry_type).and_return("document")
        allow(model).to receive(:content).and_return("content")
      end

      result = transformer.model_to_data(model)
      expect(result[:entry_type].attributes).not_to have_key("content")
    end
  end
end
