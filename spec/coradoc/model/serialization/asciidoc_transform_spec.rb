# frozen_string_literal: true

RSpec.describe Coradoc::Model::Serialization::AsciidocTransform do
  # Helper methods for creating test doubles
  def create_attribute_double(name, type, collection: false)
    double(name,
      type: type,
      collection?: collection,
      derived?: false,
      cast: ->(value, _format, _options) { value }
    )
  end

  # Shared context for common model setup
  shared_context "with basic model setup" do
    let(:instance_model) do
      double("InstanceModel").tap do |model|
        allow(model).to receive(:title=)
        allow(model).to receive(:title).and_return("Test Document")
        allow(model).to receive(:document_attributes=)
        allow(model).to receive(:document_attributes).and_return({ "lang" => "en" })
        allow(model).to receive(:sections=)
        allow(model).to receive(:sections).and_return(["Section 1", "Section 2"])
        allow(model).to receive(:using_default?).and_return(false)
        allow(model).to receive(:using_default_for)
      end
    end

    let(:model_class) do
      double("ModelClass").tap do |klass|
        allow(klass).to receive(:name).and_return("TestDocument")
        allow(klass).to receive(:entry_type).and_return("document")
        allow(klass).to receive(:content).and_return("content")
        allow(klass).to receive(:title).and_return("Test Document")
        allow(klass).to receive(:new).and_return(instance_model)
      end
    end
  end

  # Shared context for attribute setup
  shared_context "with attribute setup" do
    let(:attributes) do
      {
        "title" => create_attribute_double("TitleAttribute", String),
        "document_attributes" => create_attribute_double("DocumentAttributesAttribute", Hash),
        "sections" => create_attribute_double("SectionsAttribute", Array, collection: true)
      }
    end

    let(:mapping_methods) do
      {
        name: "title",
        to: "title",
        field_type: :attribute,
        entry_type?: false,
        content?: false,
        render_nil: false,
        render_default: false,
        delegate: nil,
        custom_methods: { from: nil },
        value_map: (proc { |dir, _| {} }),
        deserialize: (proc { |instance, value, _attrs, _ctx|
          instance.public_send(:"#{:title}=", value)
        })
      }
    end

    let(:mappings) do
      double("Mappings").tap do |mappings|
        allow(mappings).to receive(:mappings).and_return([
          double("Mapping", mapping_methods.merge(
            name: "title",
            to: "title",
            field_type: :attribute
          )),
          double("Mapping", mapping_methods.merge(
            name: "document_attributes",
            to: "document_attributes",
            field_type: :document_attributes
          )),
          double("Mapping", mapping_methods.merge(
            name: "sections",
            to: "sections",
            field_type: :sections
          ))
        ])
      end
    end
  end

  describe ".data_to_model" do
    include_context "with basic model setup"
    include_context "with attribute setup"

    let(:context) do
      double("Context").tap do |ctx|
        allow(ctx).to receive(:mappings_for).with(:asciidoc).and_return(mappings)
        allow(ctx).to receive(:attributes).and_return(attributes)
        allow(ctx).to receive(:model).and_return(model_class)
      end
    end

    let(:transformer) { described_class.new(context) }

    let(:data) do
      double("Data").tap do |data|
        allow(data).to receive(:attributes).and_return({
          type: double("Entry",
            entry_type: "document",
            content: "test content",
            attributes: {
              "title" => "Test Document",
              "document_attributes" => { "lang" => "en" },
              "sections" => ["Section 1", "Section 2"]
            }
          )
        })
      end
    end

    it "transforms data to model preserving all attributes" do
      result = described_class.data_to_model(context, data, :asciidoc)
      expect(result).to be_a(instance_model.class)
      expect(result.title).to eq("Test Document")
      expect(result.document_attributes).to eq({ "lang" => "en" })
      expect(result.sections).to eq(["Section 1", "Section 2"])
    end

    context "with collection attributes" do
      let(:items) do
        [
          double("Item", to_adoc: "item1"),
          double("Item", to_adoc: "item2")
        ]
      end

      let(:collection_instance) do
        double("CollectionInstance").tap do |instance|
          allow(instance).to receive(:items=)
          allow(instance).to receive(:items).and_return(items)
          allow(instance).to receive(:using_default?).and_return(false)
          allow(instance).to receive(:using_default_for)
        end
      end

      let(:collection_class) do
        double("CollectionClass").tap do |klass|
          allow(klass).to receive(:name).and_return("TestCollection")
          allow(klass).to receive(:entry_type).and_return("list")
          allow(klass).to receive(:new).and_return(collection_instance)
        end
      end

      let(:collection_mapping) do
        double("Mapping", mapping_methods.merge(
          name: "items",
          to: "items",
          field_type: :collection
        ))
      end

      before do
        allow(mappings).to receive(:mappings).and_return([collection_mapping])
        allow(context).to receive(:model).and_return(collection_class)
        attributes["items"] = create_attribute_double("ItemsAttribute", Array, collection: true)
      end

      it "handles collection attributes correctly" do
        data = double("Data").tap do |data|
          allow(data).to receive(:attributes).and_return({
            type: double("Entry",
              entry_type: "list",
              content: "",
              attributes: { "items" => items }
            )
          })
        end

        result = described_class.data_to_model(context, data, :asciidoc)
        expect(result).to be_a(collection_instance.class)
        expect(result.items).to eq(items)
      end
    end
  end

  describe "validation" do
    include_context "with basic model setup"
    include_context "with attribute setup"

    let(:context) do
      double("Context").tap do |ctx|
        allow(ctx).to receive(:mappings_for).with(:asciidoc).and_return(mappings)
        allow(ctx).to receive(:attributes).and_return(attributes)
        allow(ctx).to receive(:model).and_return(model_class)
      end
    end

    it "raises error for invalid document format" do
      expect {
        described_class.data_to_model(context, [], :asciidoc)
      }.to raise_error(Lutaml::Model::CollectionTrueMissingError)
    end
  end
end
