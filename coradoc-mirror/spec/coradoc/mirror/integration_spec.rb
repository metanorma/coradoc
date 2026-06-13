# frozen_string_literal: true

require "spec_helper"
require "json"
require "yaml"

RSpec.describe "End-to-end integration" do
  describe "YAML output" do
    it "produces valid YAML output" do
      doc = Coradoc::CoreModel::DocumentElement.new(
        title: "YAML Test",
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: "Hello"),
        ],
      )

      yaml = Coradoc::Mirror.to_yaml(doc)
      parsed = YAML.safe_load(yaml)
      expect(parsed["type"]).to eq("doc")
      expect(parsed["attrs"]["title"]).to eq("YAML Test")
    end

    it "round-trips YAML serialization" do
      doc = Coradoc::CoreModel::DocumentElement.new(
        title: "YAML Round Trip",
        children: [
          Coradoc::CoreModel::SectionElement.new(
            title: "Section",
            level: 1,
            children: [
              Coradoc::CoreModel::ParagraphBlock.new(content: "Text"),
            ],
          ),
        ],
      )

      yaml = Coradoc::Mirror.to_yaml(doc)
      mirror_node = Coradoc::Mirror::Node.from_h(YAML.safe_load(yaml))
      expect(mirror_node).to be_a(Coradoc::Mirror::Node::Document)
      expect(mirror_node.title).to eq("YAML Round Trip")
    end
  end

  describe "Transformer facade" do
    it "supports forward and reverse transformation" do
      transformer = Coradoc::Mirror::Transformer.new

      doc = Coradoc::CoreModel::DocumentElement.new(
        title: "Test",
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: "Content"),
        ],
      )

      mirror = transformer.from_core_model(doc)
      expect(mirror).to be_a(Coradoc::Mirror::Node::Document)

      restored = transformer.to_core_model(mirror)
      expect(restored).to be_a(Coradoc::CoreModel::DocumentElement)
      expect(restored.title).to eq("Test")
    end
  end

  describe "JSON round-trip" do
    it "serializes and deserializes through JSON" do
      original = Coradoc::CoreModel::DocumentElement.new(
        title: "JSON Round Trip",
        children: [
          Coradoc::CoreModel::SectionElement.new(
            title: "Intro",
            level: 1,
            id: "intro",
            children: [
              Coradoc::CoreModel::ParagraphBlock.new(content: "Hello"),
            ],
          ),
        ],
      )

      json = Coradoc::Mirror.to_json(original, pretty: true)
      parsed = JSON.parse(json)

      # Reconstruct from JSON
      mirror_node = Coradoc::Mirror::Node.from_h(parsed)
      expect(mirror_node).to be_a(Coradoc::Mirror::Node::Document)
      expect(mirror_node.title).to eq("JSON Round Trip")
    end
  end

  describe "with AsciiDoc", if: Gem.loaded_specs.key?("coradoc-adoc") do
    before(:each) do
      require "coradoc/asciidoc"
    end

    it "transforms a complete AsciiDoc document to mirror JSON" do
      adoc = <<~ADOC
        = Integration Test
        Author Name

        == Introduction

        This has *bold* and _italic_ text.

        === Details

        [source,ruby]
        ----
        def hello
          puts "world"
        end
        ----

        * Item one
        * Item two

        NOTE: Pay attention to this.
      ADOC

      doc = Coradoc.parse(adoc, format: :asciidoc)
      mirror = Coradoc::Mirror.transform(doc)

      expect(mirror).to be_a(Coradoc::Mirror::Node::Document)
      expect(mirror.title).to eq("Integration Test")

      json = mirror.to_json(pretty: true)
      parsed = JSON.parse(json)
      expect(parsed["type"]).to eq("doc")
      expect(parsed["content"].length).to be >= 2

      sections = parsed["content"].select { |c| c["type"] == "section" }
      expect(sections.length).to be >= 1
    end
  end
end
