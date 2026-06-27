# frozen_string_literal: true

require 'spec_helper'
require 'coradoc-mirror' if Gem.loaded_specs.key?('coradoc-mirror')
require 'json'

# Regression coverage for the AsciiDoc inline passthrough bug
# (BUG-asciidoc-inline-passthrough-lost.md). The `+++raw+++` syntax
# must round-trip through CoreModel into a typed raw_inline node —
# never a plain text node — so downstream renderers can emit the
# content verbatim without sniffing.
RSpec.describe 'AsciiDoc inline passthrough (BUG repro)',
               if: Gem.loaded_specs.key?('coradoc-mirror') do
  let(:adoc) do
    'Easy +++<abbr title="What you see is what you mean">WYSIWYM</abbr>+++ semantic.'
  end

  let(:doc)  { Coradoc.parse(adoc, format: :asciidoc) }
  let(:json) { Coradoc.serialize(doc, to: :mirror_json) }
  let(:tree) { JSON.parse(json) }

  def find_nodes(node, type)
    return [node] if node.is_a?(Hash) && node['type'] == type
    return [] unless node.is_a?(Hash)

    Array(node['content']).flat_map { |child| find_nodes(child, type) }
  end

  it 'emits a typed raw_inline node (not a plain text node)' do
    raws = find_nodes(tree, 'raw_inline')
    expect(raws).not_to be_empty,
                        "expected raw_inline node; full JSON: #{json}"
  end

  it 'carries the verbatim payload on the raw_inline node' do
    raws = find_nodes(tree, 'raw_inline')
    expect(raws.first['text'])
      .to eq('<abbr title="What you see is what you mean">WYSIWYM</abbr>')
  end

  it 'does not leak the +++ delimiter as a text node' do
    text_nodes = find_nodes(tree, 'text')
    leaked = text_nodes.select { |t| t['text'].to_s == '+++' }
    expect(leaked).to be_empty,
                      "+++ delimiters leaked into text nodes: #{leaked.inspect}"
  end

  it 'preserves the raw payload on round-trip back to AsciiDoc' do
    serialized = Coradoc.serialize(doc, to: :asciidoc)
    expect(serialized).to include('+++<abbr')
    expect(serialized).to include('WYSIWYM</abbr>+++')
  end

  it 'preserves the typed node on mirror round-trip' do
    node = Coradoc::Mirror.from_hash(tree)
    core = Coradoc::Mirror::MirrorToCoreModel.new.call(node)
    expect(core).to be_a(Coradoc::CoreModel::DocumentElement)

    raw_inline = find_raw_inline(core)
    expect(raw_inline).not_to be_nil
    expect(raw_inline.content)
      .to eq('<abbr title="What you see is what you mean">WYSIWYM</abbr>')
  end

  def find_raw_inline(node)
    queue = [node]
    until queue.empty?
      current = queue.shift
      return current if current.is_a?(Coradoc::CoreModel::RawInlineElement)

      next unless current.is_a?(Coradoc::CoreModel::HasChildren)

      queue.concat(Array(current.children))
    end
    nil
  end
end
