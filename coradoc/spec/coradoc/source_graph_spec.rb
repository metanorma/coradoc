# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'

RSpec.describe Coradoc::SourceGraph do
  def sidecar_at(dir)
    Coradoc::SourceGraph::Sidecar.new(File.join(dir, 'cache'))
  end

  def write(dir, name, content)
    File.write(File.join(dir, name), content)
    File.join(dir, name)
  end

  def build_graph(paths, sidecar)
    Coradoc::SourceGraph.build(paths, sidecar: sidecar)
  end

  describe 'lazy levels' do
    it 'does not parse until asked' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.parsed?).to be(false)
        expect(node.derived_digest).to be_nil
      end
    end

    it 'parses to the format tree and materializes CoreModel' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.parsed).to be_a(Coradoc::AsciiDoc::Model::Document)
        core = graph.materialize(node)
        expect(core).to be_a(Coradoc::CoreModel::DocumentElement)
        expect(node.parsed?).to be(true)
        expect(node.derived_digest).to match(/\A[0-9a-f]{64}\z/)
      end
    end

    it 'caches the CoreModel materialization' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)

        expect(node.core).to equal(node.core)
      end
    end

    it 'raises for an unregistered extension' do
      Dir.mktmpdir do |dir|
        blob = write(dir, 'blob.xyz', 'content')
        node = build_graph(blob, sidecar_at(dir)).node(blob)

        expect { node.parsed }
          .to raise_error(Coradoc::UnsupportedFormatError)
      end
    end
  end

  describe 'freshness and demotion' do
    it 'reports a content-edited node as stale and demotes it' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\nbody\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)

        write(dir, 'doc.adoc', "= Title\n\nedited\n")
        stale = graph.stale_nodes

        expect(stale.map(&:path)).to contain_exactly(node.path)
        expect(node.parsed?).to be(false)
      end
    end

    it 'propagates staleness up the include edges' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)

        expect(graph.edges(doc)).to eq([File.expand_path(part)])

        write(dir, 'part.adoc', "changed\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        # part has no derived state in a cold graph, so only the
        # includer is stale — but its parsed level is demoted.
        expect(stale).to eq(%w[doc.adoc])
        expect(node.parsed?).to be(false)
      end
    end

    it 'propagates transitively through chains' do
      Dir.mktmpdir do |dir|
        write(dir, 'leaf.adoc', "leaf\n")
        mid = write(dir, 'mid.adoc', "mid\n\ninclude::leaf.adoc[]\n")
        root = write(dir, 'root.adoc', "= R\n\ninclude::mid.adoc[]\n")
        graph = build_graph(root, sidecar_at(dir))
        root_node = graph.node(root)
        graph.materialize(root_node)
        graph.materialize(graph.node(mid))

        write(dir, 'leaf.adoc', "leaf2\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        # leaf was never materialized; both includers are stale.
        expect(stale.sort).to eq(%w[mid.adoc root.adoc])
      end
    end

    it 'terminates on circular includes' do
      Dir.mktmpdir do |dir|
        a = write(dir, 'a.adoc', "a\n\ninclude::b.adoc[]\n")
        b = write(dir, 'b.adoc', "b\n\ninclude::a.adoc[]\n")
        graph = build_graph(a, sidecar_at(dir))
        node = graph.node(a)
        graph.materialize(node)
        graph.materialize(graph.node(b))

        write(dir, 'b.adoc', "b2\n\ninclude::a.adoc[]\n")
        stale = graph.stale_nodes.map { |n| File.basename(n.path) }

        expect(stale.sort).to eq(%w[a.adoc b.adoc])
      end
    end

    it 'flags the includer when a NEW include appears (structural drift)' do
      Dir.mktmpdir do |dir|
        write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist

        write(dir, 'new.adoc', "new\n")
        write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n\ninclude::new.adoc[]\n")

        expect(graph.stale_nodes.map(&:path)).to contain_exactly(node.path)
      end
    end
  end

  describe Coradoc::SourceGraph::Sidecar do
    it 'prefers CORADOC_CACHE_DIR, then XDG_CACHE_HOME, then ~/.cache' do
      old = [ENV.fetch('CORADOC_CACHE_DIR', nil), ENV.fetch('XDG_CACHE_HOME', nil)]
      begin
        ENV['CORADOC_CACHE_DIR'] = '/tmp/coradoc-override'
        expect(described_class.default_dir).to eq('/tmp/coradoc-override')

        ENV['CORADOC_CACHE_DIR'] = nil
        ENV['XDG_CACHE_HOME'] = '/tmp/xdg-home'
        expect(described_class.default_dir).to eq('/tmp/xdg-home/coradoc')

        ENV['XDG_CACHE_HOME'] = nil
        expect(described_class.default_dir)
          .to eq(File.join(Dir.home, '.cache', 'coradoc'))
      ensure
        ENV['CORADOC_CACHE_DIR'], ENV['XDG_CACHE_HOME'] = old
      end
    end

    it 'round-trips digests, edges, and lazily minted ids' do
      Dir.mktmpdir do |dir|
        part = write(dir, 'part.adoc', "included\n")
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist

        payload = JSON.parse(File.read(sidecar_at(dir).path))
        doc_record = payload[File.expand_path(doc)]
        part_record = payload[File.expand_path(part)]

        expect(doc_record['edges']).to eq([File.expand_path(part)])
        expect(doc_record['digest']).to eq(node.derived_digest)
        expect(doc_record['id']).to match(/\An\d{8}\z/)
        expect(part_record['id']).to match(/\An\d{8}\z/)
        expect(part_record['id']).not_to eq(doc_record['id'])
      end
    end

    it 'keeps ids stable across rewrites' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n")
        graph = build_graph(doc, sidecar_at(dir))
        node = graph.node(doc)
        graph.materialize(node)
        graph.persist
        first_id = sidecar_at(dir).record_for(doc)['id']

        graph.persist

        expect(sidecar_at(dir).record_for(doc)['id']).to eq(first_id)
      end
    end

    it 'evicts the oldest records beyond the cap' do
      Dir.mktmpdir do |dir|
        sidecar = sidecar_at(dir)
        records = (1..3).map do |i|
          { path: File.join(dir, "f#{i}.adoc"), id: nil,
            digest: "d#{i}", edges: [] }
        end
        stub_const("#{described_class}::MAX_ENTRIES", 2)
        sidecar.write(records)

        keys = sidecar.entries.keys.map { |p| File.basename(p) }
        expect(keys).to eq(%w[f2.adoc f3.adoc])
      end
    end

    it 'treats a corrupt cache file as empty' do
      Dir.mktmpdir do |dir|
        sidecar = sidecar_at(dir)
        FileUtils.mkdir_p(sidecar.dir)
        File.write(sidecar.path, '{not json')

        expect(sidecar.entries).to eq({})
      end
    end
  end

  describe 'warm rebuilds' do
    it 'reuses digests without parsing and reports no stale nodes' do
      Dir.mktmpdir do |dir|
        doc = write(dir, 'doc.adoc', "= Title\n\ninclude::part.adoc[]\n")
        write(dir, 'part.adoc', "included\n")
        cold = build_graph(doc, sidecar_at(dir))
        cold.materialize(cold.node(doc))
        cold_digest = cold.node(doc).derived_digest
        cold.persist

        warm = build_graph(doc, sidecar_at(dir))
        warm_node = warm.node(doc)

        expect(warm.stale_nodes).to be_empty
        expect(warm_node.digest).to eq(cold_digest)
        expect(warm_node.parsed?).to be(false)

        write(dir, 'part.adoc', "changed\n")
        expect(warm.stale_nodes.map { |n| File.basename(n.path) }.sort)
          .to eq(%w[doc.adoc part.adoc])
      end
    end
  end
end
