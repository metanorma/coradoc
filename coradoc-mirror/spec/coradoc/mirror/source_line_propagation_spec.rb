# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Round-trip coverage for source_line across the Mirror seam.
# CoreModel sets source_line via the AsciiDoc parser; the Mirror layer
# must preserve it in memory on both legs of the round-trip so editor
# integrations (linters, formatters) can still map AST nodes back to
# source text after a CoreModel → Mirror → CoreModel hop.
#
# Wire format note: source_line is intentionally absent from every
# Mirror Node `key_value` mapping. It is parser metadata, not part of
# the ProseMirror JSON contract. Memory round-trips preserve it; JSON
# serialization omits it.
RSpec.describe 'Mirror source_line propagation', :asciidoc do
  let(:reverse) { Coradoc::Mirror::MirrorToCoreModel.new }
  let(:forward) { Coradoc::Mirror::CoreModelToMirror.new }

  describe 'CoreModel → Mirror (forward)' do
    let(:paragraph) do
      Coradoc::CoreModel::ParagraphBlock.new(content: 'hello', source_line: 42)
    end
    let(:doc) { Coradoc::CoreModel::DocumentElement.new(children: [paragraph]) }
    let(:node) { Coradoc::Mirror.transform(doc).content.first }

    it 'copies source_line onto the produced Mirror node' do
      expect(node.source_line).to eq(42)
    end

    it 'does not serialise source_line into the JSON wire format' do
      json = Coradoc.serialize(doc, to: :mirror_json)
      parsed = JSON.parse(json)
      paragraph_node = parsed.dig('content', 0)

      expect(paragraph_node.key?('source_line')).to be(false)
    end
  end

  describe 'Mirror → CoreModel (reverse)' do
    let(:mirror_node) do
      Coradoc::Mirror::Node::Paragraph.new(source_line: 7)
    end
    let(:mirror_doc) { Coradoc::Mirror::Node::Document.new(content: [mirror_node]) }
    let(:rebuilt) { reverse.call(mirror_doc).children.first }

    it 'copies source_line onto the rebuilt CoreModel node' do
      expect(rebuilt.source_line).to eq(7)
    end
  end

  describe 'full round-trip preserves source_line' do
    let(:original) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'first', source_line: 3),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'second', source_line: 5)
        ]
      )
    end
    let(:mirror_doc) { forward.call(original) }
    let(:rebuilt) { reverse.call(mirror_doc) }

    it 'preserves source_line on the first paragraph' do
      expect(rebuilt.children[0].source_line).to eq(3)
    end

    it 'preserves source_line on the second paragraph' do
      expect(rebuilt.children[1].source_line).to eq(5)
    end
  end

  describe 'source_line absent on input' do
    let(:paragraph) do
      Coradoc::CoreModel::ParagraphBlock.new(content: 'x')
    end
    let(:doc) { Coradoc::CoreModel::DocumentElement.new(children: [paragraph]) }
    let(:node) { Coradoc::Mirror.transform(doc).content.first }

    it 'leaves the Mirror node source_line unset' do
      expect(node.source_line).to be_nil
    end
  end

  describe 'source_line already set on the output node' do
    let(:original_node) do
      Coradoc::Mirror::Node::Paragraph.new(source_line: 99)
    end
    let(:mirror_doc) { Coradoc::Mirror::Node::Document.new(content: [original_node]) }

    it 'reverse builder does not overwrite an explicit source_line', :aggregate_failures do
      rebuilt = reverse.call(mirror_doc).children.first
      expect(rebuilt.source_line).to eq(99)
    end
  end
end
