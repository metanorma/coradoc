# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Edge do
  let(:address) { Coradoc::Reference::Address.parse('ELF-5005-1#sec-3') }

  describe '.build' do
    it 'creates a navigation edge with kind-specific options' do
      edge = described_class.build(
        kind: :navigation,
        address: address,
        source_id: 'para-1',
        label: 'Section 3',
        options: { tooltip: 'Go to Section 3' }
      )
      expect(edge.kind).to eq('navigation')
      expect(edge.address).to eq(address)
      expect(edge.source_id).to eq('para-1')
      expect(edge.label).to eq('Section 3')
      expect(edge.options).to be_a(Coradoc::Reference::Edge::NavigationOptions)
      expect(edge.options.tooltip).to eq('Go to Section 3')
    end

    it 'creates a citation edge with citation options' do
      edge = described_class.build(
        kind: :citation,
        address: address,
        options: { style: 'ieee' }
      )
      expect(edge.kind).to eq('citation')
      expect(edge.options).to be_a(Coradoc::Reference::Edge::CitationOptions)
      expect(edge.options.style).to eq('ieee')
      expect(edge.options.suppress_author).to be(false)
    end

    it 'creates a link edge' do
      edge = described_class.build(
        kind: :link,
        address: address,
        options: { role: 'external' }
      )
      expect(edge.options).to be_a(Coradoc::Reference::Edge::LinkOptions)
      expect(edge.options.role).to eq('external')
    end

    it 'creates an include edge embedding the canonical IncludeOptions' do
      options = Coradoc::CoreModel::IncludeOptions.from_hash({ 'tags' => 'a;b' })
      edge = described_class.build(
        kind: :include,
        address: address,
        options: { include_options: options }
      )
      expect(edge.kind).to eq('include')
      expect(edge.options).to be_a(Coradoc::Reference::Edge::IncludeOptions)
      expect(edge.options.include_options).to be(options)
      expect(edge.options.include_options.tags).to eq(%w[a b])
    end

    it 'creates an image_ref edge' do
      edge = described_class.build(
        kind: :image_ref,
        address: address,
        options: { alt_text: 'Diagram', width: '100%' }
      )
      expect(edge.options).to be_a(Coradoc::Reference::Edge::ImageRefOptions)
      expect(edge.options.alt_text).to eq('Diagram')
      expect(edge.options.width).to eq('100%')
    end

    it 'creates a footnote_ref edge' do
      edge = described_class.build(
        kind: :footnote_ref,
        address: address,
        options: { footnote_id: 'fn-1' }
      )
      expect(edge.options).to be_a(Coradoc::Reference::Edge::FootnoteRefOptions)
      expect(edge.options.footnote_id).to eq('fn-1')
    end

    it 'uses default options when none given' do
      edge = described_class.build(kind: :navigation, address: address)
      expect(edge.options).to be_a(Coradoc::Reference::Edge::NavigationOptions)
      expect(edge.options.tooltip).to be_nil
    end
  end

  describe '.register_kind (OCP)' do
    let(:custom_options_class) do
      Class.new(Coradoc::Reference::Edge::Options) do
        attribute :extra, :string
      end
    end

    after { described_class::Kind.reset! }

    it 'registers a new kind with its options class' do
      described_class.register_kind(:custom, options_class: custom_options_class)
      edge = described_class.build(
        kind: :custom,
        address: address,
        options: { extra: 'value' }
      )
      expect(edge.kind).to eq('custom')
      expect(edge.options).to be_a(custom_options_class)
      expect(edge.options.extra).to eq('value')
    end

    it 'is not clobbered by lazy builtin registration when registered first' do
      described_class::Kind.reset!
      described_class.register_kind(:navigation, options_class: custom_options_class)
      edge = described_class.build(kind: :navigation, address: address)
      expect(edge.options).to be_a(custom_options_class)
    end
  end

  describe '.kinds' do
    it 'returns all registered kinds including builtins' do
      expect(described_class.kinds).to include(
        :navigation, :citation, :link, :include, :image_ref, :footnote_ref
      )
    end
  end

  describe '.build (unknown kind)' do
    it 'raises UnknownKindError naming the kind' do
      expect { described_class.build(kind: :bogus, address: address) }
        .to raise_error(Coradoc::Reference::UnknownKindError, /bogus/)
    end
  end

  describe 'value equality' do
    it 'treats equal attributes as equal' do
      a = described_class.build(kind: :navigation, address: address, source_id: 'x')
      b = described_class.build(kind: :navigation, address: address, source_id: 'x')
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end

    it 'never equates a base Options with a subclass instance (either direction)' do
      base = Coradoc::Reference::Edge::Options.new
      sub = Coradoc::Reference::Edge::NavigationOptions.new
      expect(base).not_to eq(sub)
      expect(sub).not_to eq(base)
    end

    it 'distinguishes different kinds' do
      a = described_class.build(kind: :navigation, address: address)
      b = described_class.build(kind: :link, address: address)
      expect(a).not_to eq(b)
    end

    it 'distinguishes different source ids' do
      a = described_class.build(kind: :navigation, address: address, source_id: 'x')
      b = described_class.build(kind: :navigation, address: address, source_id: 'y')
      expect(a).not_to eq(b)
    end
  end
end
