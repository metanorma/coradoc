# frozen_string_literal: true

RSpec.describe Coradoc::Model::ListItem do
  describe ".initialize" do
    it "initializes with basic attributes" do
      content = [Coradoc::Model::TextElement.new(content: "List item content")]
      item = described_class.new(
        id: "item-1",
        content:,
        marker: "*",
        subitem: nil,
        line_break: "\n"
      )

      expect(item.id).to eq("item-1")
      expect(item.content).to eq content
      expect(item.marker).to eq("*")
      expect(item.subitem).to be_nil
      expect(item.line_break).to eq("\n")
    end

    it "initializes with empty collections" do
      item = described_class.new
      expect(item.attached).to be_empty
      expect(item.nested).to be_nil
    end
  end

  describe "#to_asciidoc" do
    context "with simple content" do
      it "generates basic list item" do
        content = [Coradoc::Model::TextElement.new(content: "Simple item")]
        item = described_class.new(
          content:,
          line_break: "\n"
        )

        expect(item.to_asciidoc).to eq(" Simple item\n")
      end

      it "includes anchor when present" do
        content = [Coradoc::Model::TextElement.new(content: "Simple item")]

        item = described_class.new(
          content:,
          line_break: "\n"
        )
        allow(item).to receive(:id).and_return("item-1")

        expect(item.to_asciidoc).to eq(" [[item-1]]Simple item\n")
      end
    end

    context "with attached content" do
      let(:paragraph) { instance_double(Coradoc::Model::Paragraph, to_asciidoc: "Additional paragraph") }
      let(:text_element) { Coradoc::Model::TextElement.new(content: "Item with attachment") }

      it "includes attached content" do
        item = described_class.new(
          content: [text_element],
          line_break: "\n",
          attached: [paragraph]
        )

        expected_output = " Item with attachment\n+\nAdditional paragraph"
        expect(item.to_asciidoc).to eq(expected_output)
      end
    end

    context "with nested list" do
      let(:nested_list) { instance_double(Coradoc::Model::List::Nestable, to_asciidoc: "\n** Nested item") }
      let(:text_element) { Coradoc::Model::TextElement.new(content: "Parent item") }

      it "includes nested content" do
        item = described_class.new(
          content: [text_element],
          line_break: "\n",
          nested: nested_list
        )

        expected_output = " Parent item\n\n** Nested item"
        expect(item.to_asciidoc).to eq(expected_output)
      end
    end

    context "with complex content" do
      let(:text_element) { Coradoc::Model::TextElement.new }

      it "handles array content" do
        item = described_class.new(
          content: [text_element],
          line_break: "\n"
        )

        allow(text_element).to receive(:to_asciidoc).and_return("Complex content")
        expect(item.to_asciidoc).to include("Complex content")
      end

      it "handles empty content" do
        item = described_class.new(line_break: "\n")
        expect(item.to_asciidoc).to eq(" {empty}\n")
      end
    end
  end

  describe "inheritance and includes" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end

  describe "constants" do
    it "defines HARDBREAK_MARKERS" do
      expect(described_class::HARDBREAK_MARKERS).to eq([:hardbreak, :init])
    end

    it "defines STRIP_UNICODE_BEGIN_MARKERS" do
      expect(described_class::STRIP_UNICODE_BEGIN_MARKERS).to eq([:hardbreak, :init, false])
    end

    it "defines STRIP_UNICODE_END_MARKERS" do
      expect(described_class::STRIP_UNICODE_END_MARKERS).to eq([:hardbreak, :end, false])
    end
  end
end
