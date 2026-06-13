require "spec_helper"

RSpec.describe Coradoc::Mirror::Handlers::Toc do
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe ".call" do
    it "creates a toc node with entries" do
      entry1 = Coradoc::CoreModel::TocEntry.new(
        id: "sec-1",
        title: "Section 1",
        level: 1
      )

      entry2 = Coradoc::CoreModel::TocEntry.new(
        id: "sec-1-1",
        title: "Section 1.1",
        level: 2
      )

      entry1.children = [entry2]

      element = Coradoc::CoreModel::Toc.new(
        title: "Table of Contents",
        entries: [entry1]
      )

      node = described_class.call(element, context: context)
      expect(node).to be_a(Coradoc::Mirror::Node::Toc)
      expect(node.type).to eq("toc")
      expect(node.title).to eq("Table of Contents")
      expect(node.content.length).to eq(1)

      entry_node = node.content.first
      expect(entry_node).to be_a(Coradoc::Mirror::Node::TocEntry)
      expect(entry_node.id).to eq("sec-1")
      expect(entry_node.title).to eq("Section 1")
      expect(entry_node.level).to eq(1)

      sub_entry_node = entry_node.content.first
      expect(sub_entry_node).to be_a(Coradoc::Mirror::Node::TocEntry)
      expect(sub_entry_node.id).to eq("sec-1-1")
    end

    it "creates empty toc node if no entries" do
      element = Coradoc::CoreModel::Toc.new(title: "Empty TOC")

      node = described_class.call(element, context: context)
      expect(node.type).to eq("toc")
      expect(node.title).to eq("Empty TOC")
      expect(node.content).to be_empty
    end
  end
end
