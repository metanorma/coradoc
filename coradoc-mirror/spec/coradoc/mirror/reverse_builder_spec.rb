# frozen_string_literal: true

require 'spec_helper'

# Locks in the OCP guarantee for the reverse builder registry: every
# Mirror Node subclass that is serializable (PM_TYPE declared) has a
# registered builder, and adding a new builder is purely additive.
RSpec.describe Coradoc::Mirror::ReverseBuilder do
  describe 'REGISTRY coverage' do
    it 'registers a builder for every Node PM_TYPE' do
      node_types = Coradoc::Mirror::Node::NODES.keys
      registered = described_class.registered_types

      missing = node_types - registered
      expect(missing).to be_empty,
                         "Mirror Node types without a reverse builder: #{missing.inspect}"
    end
  end

  describe 'lookup' do
    it 'returns a class for a known type' do
      expect(described_class.lookup('doc')).to be_a(Class)
      expect(described_class.lookup('doc').ancestors)
        .to include(described_class::Base)
    end

    it 'returns nil for an unknown type' do
      expect(described_class.lookup('does_not_exist')).to be_nil
    end
  end

  describe 'extension (OCP)' do
    # Build a throwaway builder class, register it under a synthetic type,
    # and verify it is dispatched — without editing any existing code.
    let(:synthetic_type) { 'rspec_synthetic_type' }

    # Lightweight Node-like struct (real Ruby object, not a double) carrying
    # just enough surface for MirrorToCoreModel dispatch + the synthetic
    # builder's #build to read what they need.
    SyntheticNode = Struct.new(:type, :text, :content, :marks, :title, :id)

    after do
      described_class::REGISTRY.delete(synthetic_type)
    end

    it 'routes a new type to a newly added builder' do
      synthetic_class = Class.new(described_class::Base) do
        registers('rspec_synthetic_type')

        def build(node)
          Coradoc::CoreModel::ParagraphBlock.new(content: "synthetic:#{node.text}")
        end
      end

      expect(described_class.lookup(synthetic_type)).to eq(synthetic_class)

      node = SyntheticNode.new(synthetic_type, 'x', [], [], nil, nil)
      core = Coradoc::Mirror::MirrorToCoreModel.new.call(
        Coradoc::Mirror::Node::Document.new(content: [node])
      )
      para = core.children.first
      expect(para).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(para.content.to_s).to eq('synthetic:x')
    end
  end
end
