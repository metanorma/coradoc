# frozen_string_literal: true

require "spec_helper"

RSpec.describe Coradoc::Mirror::Node do
  describe "construction" do
    it "creates a basic node with type" do
      node = described_class.new(type: "custom")
      expect(node.type).to eq("custom")
      expect(node.content).to eq([])
      expect(node.marks).to eq([])
    end

    it "uses PM_TYPE as default type" do
      node = described_class.new
      expect(node.type).to eq("node")
    end
  end

  describe "typed attributes" do
    it "Document has title and id accessors" do
      doc = described_class::Document.new(title: "My Doc", id: "doc-1")
      expect(doc.title).to eq("My Doc")
      expect(doc.id).to eq("doc-1")
    end

    it "Section has title, id, level accessors" do
      section = described_class::Section.new(title: "Intro", id: "s1", level: 2)
      expect(section.title).to eq("Intro")
      expect(section.id).to eq("s1")
      expect(section.level).to eq(2)
    end

    it "CodeBlock has language, title, passthrough accessors" do
      code = described_class::CodeBlock.new(language: "ruby", title: "Example", passthrough: true)
      expect(code.language).to eq("ruby")
      expect(code.title).to eq("Example")
      expect(code.passthrough).to be true
    end

    it "Image has src, alt, caption, width, height accessors" do
      img = described_class::Image.new(src: "img.png", alt: "Alt", caption: "Cap", width: "100")
      expect(img.src).to eq("img.png")
      expect(img.alt).to eq("Alt")
      expect(img.caption).to eq("Cap")
      expect(img.width).to eq("100")
      expect(img.height).to be_nil
    end

    it "TableCell has colspan, rowspan, alignment, header accessors" do
      cell = described_class::TableCell.new(colspan: 2, header: true, alignment: "center")
      expect(cell.colspan).to eq(2)
      expect(cell.header).to be true
      expect(cell.alignment).to eq("center")
      expect(cell.rowspan).to be_nil
    end
  end

  describe "serialization" do
    it "serializes to hash with only non-empty fields" do
      node = described_class.new(type: "paragraph")
      expect(node.to_h).to eq({ "type" => "paragraph" })
    end

    it "includes typed attrs when set" do
      node = described_class::Heading.new(level: 1)
      expect(node.to_h).to eq({
        "type" => "heading",
        "attrs" => { "level" => 1 },
      })
    end

    it "omits nil attrs" do
      node = described_class::Section.new(title: "Intro")
      expect(node.to_h).to eq({
        "type" => "section",
        "attrs" => { "title" => "Intro" },
      })
    end

    it "includes content when present" do
      child = described_class::Text.new(text: "hello")
      node = described_class::Paragraph.new(content: [child])
      hash = node.to_h
      expect(hash["content"]).to be_an(Array)
      expect(hash["content"].length).to eq(1)
    end

    it "includes marks when present" do
      mark = Coradoc::Mirror::Mark::Bold.new
      node = described_class::Text.new(text: "bold", marks: [mark])
      hash = node.to_h
      expect(hash["marks"]).to be_an(Array)
    end

    it "serializes to JSON" do
      node = described_class::Paragraph.new
      json = node.to_json
      expect(JSON.parse(json)).to eq({ "type" => "paragraph" })
    end

    it "serializes to pretty JSON" do
      node = described_class::Paragraph.new
      json = node.to_json(pretty: true)
      expect(json).to include("\n")
    end

    it "serializes to YAML" do
      node = described_class::Section.new(id: "p1")
      yaml = node.to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed["type"]).to eq("section")
      expect(parsed["attrs"]["id"]).to eq("p1")
    end

    it "aliases to_hash to to_h" do
      node = described_class.new(type: "test")
      expect(node.to_hash).to eq(node.to_h)
    end
  end

  describe "deserialization" do
    it "reconstructs typed nodes from hash" do
      hash = {
        "type" => "section",
        "attrs" => { "title" => "Intro", "level" => 1 },
        "content" => [
          { "type" => "paragraph", "content" => [
            { "type" => "text", "text" => "Hello" },
          ]},
        ],
      }

      node = described_class.from_h(hash)
      expect(node).to be_a(described_class::Section)
      expect(node.title).to eq("Intro")
      expect(node.level).to eq(1)
      expect(node.content.length).to eq(1)

      para = node.content.first
      expect(para).to be_a(described_class::Paragraph)
      expect(para.content.first).to be_a(described_class::Text)
      expect(para.content.first.text).to eq("Hello")
    end

    it "returns nil for nil input" do
      expect(described_class.from_h(nil)).to be_nil
    end

    it "handles unknown types as generic Node" do
      hash = { "type" => "unknown_custom_type" }
      node = described_class.from_h(hash)
      expect(node).to be_a(described_class)
      expect(node.type).to eq("unknown_custom_type")
    end
  end

  describe "text_content" do
    it "returns empty string for node with no content" do
      node = described_class.new
      expect(node.text_content).to eq("")
    end

    it "collects text from descendants" do
      text = described_class::Text.new(text: "Hello ")
      text2 = described_class::Text.new(text: "World")
      para = described_class::Paragraph.new(content: [text, text2])
      expect(para.text_content).to eq("Hello World")
    end
  end

  describe "node type subclasses" do
    it "registers all subclasses in NODES map" do
      expect(described_class::NODES["doc"]).to eq(described_class::Document)
      expect(described_class::NODES["paragraph"]).to eq(described_class::Paragraph)
      expect(described_class::NODES["heading"]).to eq(described_class::Heading)
      expect(described_class::NODES["code_block"]).to eq(described_class::CodeBlock)
      expect(described_class::NODES["blockquote"]).to eq(described_class::Blockquote)
      expect(described_class::NODES["bullet_list"]).to eq(described_class::BulletList)
      expect(described_class::NODES["ordered_list"]).to eq(described_class::OrderedList)
      expect(described_class::NODES["list_item"]).to eq(described_class::ListItem)
      expect(described_class::NODES["image"]).to eq(described_class::Image)
      expect(described_class::NODES["table"]).to eq(described_class::Table)
      expect(described_class::NODES["section"]).to eq(described_class::Section)
      expect(described_class::NODES["admonition"]).to eq(described_class::Admonition)
    end

    it "Text node has text attribute" do
      node = described_class::Text.new(text: "Hello")
      expect(node.text).to eq("Hello")
      expect(node.to_h["text"]).to eq("Hello")
      expect(node.text_content).to eq("Hello")
    end

    it "Text node deserializes with marks" do
      hash = {
        "type" => "text",
        "text" => "bold text",
        "marks" => [{ "type" => "bold" }],
      }
      node = described_class::Text.from_h(hash)
      expect(node.text).to eq("bold text")
      expect(node.marks.length).to eq(1)
      expect(node.marks.first).to be_a(Coradoc::Mirror::Mark::Bold)
    end

    it "round-trips through serialization" do
      doc = described_class::Document.new(
        title: "Test",
        content: [
          described_class::Section.new(
            level: 1,
            title: "Intro",
            content: [
              described_class::Paragraph.new(
                content: [
                  described_class::Text.new(
                    text: "Hello ",
                    marks: [Coradoc::Mirror::Mark::Bold.new],
                  ),
                  described_class::Text.new(text: "world"),
                ],
              ),
            ],
          ),
        ],
      )

      json = doc.to_json(pretty: true)
      parsed = described_class.from_h(JSON.parse(json))

      expect(parsed).to be_a(described_class::Document)
      expect(parsed.title).to eq("Test")
      expect(parsed.content.length).to eq(1)
      section = parsed.content.first
      expect(section).to be_a(described_class::Section)
      expect(section.content.first.content.first.marks.first).to be_a(Coradoc::Mirror::Mark::Bold)
    end
  end
end
