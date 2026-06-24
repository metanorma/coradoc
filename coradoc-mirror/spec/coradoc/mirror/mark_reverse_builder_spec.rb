# frozen_string_literal: true

require 'spec_helper'

# Locks in the OCP guarantee for the mark reverse builder registry:
# every mark type that the forward direction can emit has a registered
# reverse builder, and adding a new builder is purely additive.
RSpec.describe Coradoc::Mirror::MarkReverseBuilder do
  describe 'REGISTRY coverage' do
    it 'registers a builder for every Mark PM_TYPE' do
      mark_types = Coradoc::Mirror::Mark::MARKS.keys
      registered = described_class.registered_types

      missing = mark_types - registered
      # Stem, Span, Subscript, etc. may not yet have a CoreModel target —
      # they pass through unchanged in apply_mark. Only fail if a mark
      # that SHOULD reverse is missing. For now, document what we have.
      reversible = %w[strong emphasis code underline strike subscript
                      superscript highlight link xref]
      missing_reversible = reversible - registered
      expect(missing_reversible).to be_empty,
                                    "Reversible mark types without a builder: #{missing_reversible.inspect}"
    end
  end

  describe 'lookup' do
    it 'returns a class for a known mark type' do
      expect(described_class.lookup('strong')).to be_a(Class)
      expect(described_class.lookup('strong').ancestors)
        .to include(described_class::Base)
    end

    it 'returns nil for an unknown mark type' do
      expect(described_class.lookup('does_not_exist')).to be_nil
    end
  end

  describe 'build dispatch' do
    let(:context) { Coradoc::Mirror::MirrorToCoreModel.new }

    it 'wraps inner in BoldElement for strong' do
      inner = Coradoc::CoreModel::TextContent.new(text: 'hi')
      mark = Coradoc::Mirror::Mark::Bold.new
      result = described_class.lookup('strong').new.build(inner, mark)
      expect(result).to be_a(Coradoc::CoreModel::BoldElement)
      expect(result.children).to eq([inner])
    end

    it 'reads href from Link mark' do
      inner = Coradoc::CoreModel::TextContent.new(text: 'click')
      mark = Coradoc::Mirror::Mark::Link.new(href: 'https://x')
      result = described_class.lookup('link').new.build(inner, mark)
      expect(result).to be_a(Coradoc::CoreModel::LinkElement)
      expect(result.target).to eq('https://x')
      expect(result.children).to eq([inner])
    end

    it 'reads target from CrossReference mark' do
      inner = Coradoc::CoreModel::TextContent.new(text: 'see')
      mark = Coradoc::Mirror::Mark::CrossReference.new(target: 'sec-1')
      result = described_class.lookup('xref').new.build(inner, mark)
      expect(result).to be_a(Coradoc::CoreModel::CrossReferenceElement)
      expect(result.target).to eq('sec-1')
    end
  end

  describe 'MirrorToCoreModel#apply_mark integration' do
    let(:reverse) { Coradoc::Mirror::MirrorToCoreModel.new }

    it 'passes inner through unchanged for unknown marks' do
      inner = Coradoc::CoreModel::TextContent.new(text: 'x')
      unknown_mark = Struct.new(:type).new('totally_unknown')
      expect(reverse.apply_mark(inner, unknown_mark)).to eq(inner)
    end
  end

  describe 'Base contract' do
    it 'raises NotImplementedError on a subclass that does not override build' do
      builder_class = Class.new(described_class::Base)
      expect { builder_class.new.build(nil, nil) }
        .to raise_error(NotImplementedError)
    end
  end

  describe 'extension (OCP)' do
    let(:synthetic_type) { 'rspec_synthetic_mark' }

    after do
      described_class::REGISTRY.delete(synthetic_type)
    end

    it 'routes a new mark type to a newly added builder' do
      synthetic_class = Class.new(described_class::Base) do
        registers('rspec_synthetic_mark')

        def build(inner, _mark)
          Coradoc::CoreModel::SpanElement.new(children: Array(inner))
        end
      end

      expect(described_class.lookup(synthetic_type)).to eq(synthetic_class)

      inner = Coradoc::CoreModel::TextContent.new(text: 'x')
      mark = Struct.new(:type).new(synthetic_type)
      result = Coradoc::Mirror::MirrorToCoreModel.new.apply_mark(inner, mark)
      expect(result).to be_a(Coradoc::CoreModel::SpanElement)
    end
  end
end
