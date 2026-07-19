# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::EdgeSearch do
  def edge_for(node)
    described_class.edges_for(node).first
  end

  describe '.edges_for (cross-references)' do
    it 'parses bareword targets as anchors' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(target: 'sec-b', id: 'x1')
      address = edge_for(node).address
      expect(address.scheme).to eq('anchor')
      expect(address.target).to eq('sec-b')
    end

    it 'parses uppercase bareword targets as anchors (in-document by definition)' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(target: 'SEC-2', id: 'x1')
      expect(edge_for(node).address.scheme).to eq('anchor')
    end

    it 'parses document#fragment targets as paths' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(target: 'doc.adoc#sec-3', id: 'x1')
      address = edge_for(node).address
      expect(address.scheme).to eq('path')
      expect(address.target).to eq('doc.adoc')
      expect(address.fragment).to eq('sec-3')
    end

    it 'leaves the label nil when no text was authored' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(target: 'sec-b', id: 'xref-9')
      expect(edge_for(node).label).to be_nil
    end

    it 'uses the authored text as label when present' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(
        target: 'sec-b', id: 'xref-9', content: 'Section B'
      )
      expect(edge_for(node).label).to eq('Section B')
    end
  end

  describe '.edges_for (images)' do
    it 'parses a bare filename as a path' do
      node = Coradoc::CoreModel::Image.new(src: 'foo.png', alt: 'x', id: 'i1')
      expect(edge_for(node).address.scheme).to eq('path')
    end

    it 'parses a relative path as a path' do
      node = Coradoc::CoreModel::Image.new(src: 'images/foo.png', alt: 'x', id: 'i1')
      address = edge_for(node).address
      expect(address.scheme).to eq('path')
      expect(address.target).to eq('images/foo.png')
    end

    it 'parses an absolute URL as a url' do
      node = Coradoc::CoreModel::Image.new(src: 'https://example.com/x.png', alt: 'x', id: 'i1')
      expect(edge_for(node).address.scheme).to eq('url')
    end
  end

  describe '.edges_for (links)' do
    it 'parses URL targets as urls' do
      node = Coradoc::CoreModel::LinkElement.new(target: 'https://example.com', id: 'l1')
      expect(edge_for(node).address.scheme).to eq('url')
    end
  end

  describe '.edges_for (includes)' do
    it 'parses adoc-looking targets as paths, not urls' do
      node = Coradoc::CoreModel::Include.new(target: 'httpx.adoc')
      address = edge_for(node).address
      expect(address.scheme).to eq('path')
      expect(address.target).to eq('httpx.adoc')
    end

    it 'parses http URLs as urls' do
      node = Coradoc::CoreModel::Include.new(target: 'https://example.com/shared.adoc')
      expect(edge_for(node).address.scheme).to eq('url')
    end

    it 'parses relative targets as paths' do
      node = Coradoc::CoreModel::Include.new(target: '../shared/common.adoc')
      address = edge_for(node).address
      expect(address.scheme).to eq('path')
      expect(address.target).to eq('../shared/common.adoc')
    end

    it 'carries the canonical typed IncludeOptions losslessly' do
      options = Coradoc::CoreModel::IncludeOptions.from_hash(
        { 'tags' => '*', 'leveloffset' => '+2' }
      )
      node = Coradoc::CoreModel::Include.new(target: 'a.adoc', options: options)
      edge = edge_for(node)
      expect(edge.options.include_options).to be(options)
      expect(edge.options.include_options.tags_wildcard).to be(true)
      expect(edge.options.include_options.leveloffset.delta).to eq(2)
    end
  end

  describe '.each_edge' do
    it 'walks nested children once and yields parent and edge' do
      doc = Coradoc::CoreModel::DocumentElement.new(
        id: 'doc', title: 'Doc',
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(
            content: 'x',
            children: [
              Coradoc::CoreModel::CrossReferenceElement.new(target: 'a', id: 'x1'),
              Coradoc::CoreModel::Image.new(src: 'p.png', alt: nil, id: 'i1')
            ]
          )
        ]
      )
      pairs = described_class.each_edge(doc).to_a
      expect(pairs.size).to eq(2)
      expect(pairs.map { |_parent, edge| edge.kind }).to eq(%w[navigation image_ref])
    end
  end
end
