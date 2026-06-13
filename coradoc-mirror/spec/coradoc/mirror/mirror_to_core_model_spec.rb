# frozen_string_literal: true

require "spec_helper"
require "json"
require "yaml"

RSpec.describe Coradoc::Mirror::MirrorToCoreModel do
  let(:reverse) { described_class.new }

  describe "round-trip: CoreModel → Mirror → CoreModel" do
    it "round-trips a simple document with title and paragraphs" do
      original = Coradoc::CoreModel::DocumentElement.new(
        title: "Round Trip",
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(
            content: "Hello world",
          ),
        ],
      )

      mirror = Coradoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      expect(restored).to be_a(Coradoc::CoreModel::DocumentElement)
      expect(restored.title).to eq("Round Trip")
      expect(restored.children).not_to be_empty
    end

    it "round-trips sections with levels" do
      original = Coradoc::CoreModel::DocumentElement.new(
        title: "Doc",
        children: [
          Coradoc::CoreModel::SectionElement.new(
            title: "Section One",
            level: 1,
            id: "section-one",
            children: [
              Coradoc::CoreModel::ParagraphBlock.new(content: "Content"),
            ],
          ),
        ],
      )

      mirror = Coradoc::Mirror.transform(original)
      restored = reverse.call(mirror)

      section = restored.children.first
      expect(section).to be_a(Coradoc::CoreModel::SectionElement)
      expect(section.title).to eq("Section One")
      expect(section.level).to eq(1)
      expect(section.id).to eq("section-one")
    end

    it "round-trips code blocks with language" do
      original = Coradoc::CoreModel::SourceBlock.new(
        content: "puts 'hi'",
        language: "ruby",
      )

      mirror = Coradoc::Mirror.transform(
        Coradoc::CoreModel::DocumentElement.new(children: [original]),
      )
      restored = reverse.call(mirror)
      code = restored.children.first

      expect(code).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(code.language).to eq("ruby")
    end

    it "round-trips unordered lists" do
      original = Coradoc::CoreModel::ListBlock.new(
        marker_type: "unordered",
        items: [
          Coradoc::CoreModel::ListItem.new(content: "First"),
          Coradoc::CoreModel::ListItem.new(content: "Second"),
        ],
      )

      mirror = Coradoc::Mirror.transform(
        Coradoc::CoreModel::DocumentElement.new(children: [original]),
      )
      restored = reverse.call(mirror)
      list = restored.children.first

      expect(list).to be_a(Coradoc::CoreModel::ListBlock)
      expect(list.marker_type).to eq("unordered")
      expect(list.items.length).to eq(2)
    end

    it "round-trips images" do
      original = Coradoc::CoreModel::Image.new(
        src: "photo.png",
        alt: "Photo",
        caption: "Figure 1",
      )

      mirror = Coradoc::Mirror.transform(
        Coradoc::CoreModel::DocumentElement.new(children: [original]),
      )
      restored = reverse.call(mirror)
      image = restored.children.first

      expect(image).to be_a(Coradoc::CoreModel::Image)
      expect(image.src).to eq("photo.png")
      expect(image.alt).to eq("Photo")
      expect(image.caption).to eq("Figure 1")
    end

    it "round-trips bold text marks" do
      bold = Coradoc::CoreModel::BoldElement.new(content: "important")
      original = Coradoc::CoreModel::ParagraphBlock.new(children: [bold])

      mirror = Coradoc::Mirror.transform(
        Coradoc::CoreModel::DocumentElement.new(children: [original]),
      )
      restored = reverse.call(mirror)
      para = restored.children.first

      expect(para).to be_a(Coradoc::CoreModel::Block)
    end

    it "round-trips tables" do
      original = Coradoc::CoreModel::Table.new(
        rows: [
          Coradoc::CoreModel::TableRow.new(
            cells: [
              Coradoc::CoreModel::TableCell.new(content: "A"),
              Coradoc::CoreModel::TableCell.new(content: "B"),
            ],
          ),
        ],
      )

      mirror = Coradoc::Mirror.transform(
        Coradoc::CoreModel::DocumentElement.new(children: [original]),
      )
      restored = reverse.call(mirror)
      table = restored.children.first

      expect(table).to be_a(Coradoc::CoreModel::Table)
      expect(table.rows.length).to eq(1)
    end
  end

  describe "error handling" do
    it "raises error for unknown node type" do
      node = Coradoc::Mirror::Node.new(type: "completely_unknown_type")
      expect { reverse.call(node) }.to raise_error(Coradoc::Mirror::Error, /Unknown mirror node type/)
    end
  end
end
