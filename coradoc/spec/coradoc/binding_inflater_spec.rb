# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::BindingInflater do
  let(:rule_model) { Struct.new(:style, :child, keyword_init: true) }
  let(:binding) do
    described_class::Binding.new(keys: %i[rule child], model: rule_model, captures: { child: :child },
                                 defaults: { style: 'x' })
  end
  let(:residual) { ->(node) { [:residual, node] } }
  let(:inflater) { described_class.new(bindings: [binding]) }

  it 'instantiates the bound model for a node whose keys match the binding' do
    result = inflater.inflate({ rule: true, child: 'leaf' }, &residual)
    expect(result).to eq(rule_model.new(style: 'x', child: 'leaf'))
  end

  it 'returns the hook result as is for a model-less binding' do
    hook = ->(attrs) { [:tree, attrs[:child]] }
    modelless = described_class::Binding.new(keys: %i[rule child], model: nil, captures: { child: :child },
                                             defaults: {}, via: hook)
    result = described_class.new(bindings: [modelless]).inflate({ rule: true, child: 'leaf' }, &residual)
    expect(result).to eq([:tree, 'leaf'])
  end

  it 'hands an unbound node to the residual untouched' do
    node = { other: 'v' }
    expect(inflater.inflate(node, &residual)).to eq([:residual, node])
  end

  it 'does not bind a node that carries extra keys' do
    node = { rule: true, child: 'a', ial: '.c' }
    expect(inflater.inflate(node, &residual)).to eq([:residual, node])
  end

  it 'recurses into captured collections, binding or falling through per node' do
    node = { rule: true, child: [{ rule: true, child: 'a' }, { other: 1 }] }
    result = inflater.inflate(node, &residual)
    expect(result.child).to eq([rule_model.new(style: 'x', child: 'a'), [:residual, { other: 1 }]])
  end

  it 'coerces string-like captures to String' do
    slice = Parsanol::Slice.new(0, 'leaf')
    result = inflater.inflate({ rule: true, child: slice }, &residual)
    expect(result.child).to be_a(String).and eq('leaf')
  end

  it 'resolves a lazily supplied model at first use' do
    lazy = described_class::Binding.new(keys: [:rule], model: -> { rule_model }, captures: {}, defaults: { style: 'l' })
    expect(described_class.new(bindings: [lazy]).inflate({ rule: true }, &residual)).to eq(rule_model.new(style: 'l'))
  end

  it 'assigns raw captures as captured, never inflating or sending them to the residual' do
    raw = described_class::Binding.new(keys: %i[rule child], model: rule_model, captures: {}, defaults: {},
                                       raw: { child: :child })
    subtree = [{ rule: true, child: 'a' }, { other: 1 }]
    result = described_class.new(bindings: [raw]).inflate({ rule: true, child: subtree }, &residual)
    expect(result.child).to equal(subtree)
  end

  it 'reports whether a node is bound without instantiating' do
    expect(inflater.bound?({ rule: true, child: 'a' })).to be(true)
    expect(inflater.bound?({ other: 1 })).to be(false)
  end

  it 'falls through everything when no bindings exist' do
    node = { rule: true, child: 'a' }
    expect(described_class.new(bindings: []).inflate(node, &residual)).to eq([:residual, node])
  end

  it 'builds the model from the attributes a via hook returns' do
    hooked = described_class::Binding.new(
      keys: [:wrapped], model: rule_model, captures: { wrapped: :wrapped }, defaults: {},
      via: ->(attributes) { { style: attributes[:wrapped][:inner].upcase } }
    )
    result = described_class.new(bindings: [hooked]).inflate({ wrapped: { inner: 'a' } }, &:itself)
    expect(result).to eq(rule_model.new(style: 'A'))
  end
end

RSpec.describe Coradoc::BindingInflater, '.from_table' do
  let(:model) { Struct.new(:style, :child, keyword_init: true) }
  let(:table) do
    { 'version' => 1,
      'rules' => { 'r' => { 'keys' => %w[rule kid], 'model' => 'M', 'captures' => {},
                            'children' => { 'child' => 'kid' }, 'defaults' => { 'style' => 'x' } } } }
  end
  let(:inflater) { described_class.from_table(table, models: ->(name) { { 'M' => model }.fetch(name) }) }

  it 'builds bindings from the embedded table, resolving the model by name' do
    result = inflater.inflate({ rule: true, kid: { rule: true, kid: 'leaf' } }) { |n| n }
    expect(result).to eq(model.new(style: 'x', child: model.new(style: 'x', child: 'leaf')))
  end

  it 'binds nothing for a missing table' do
    node = { rule: true }
    expect(described_class.from_table(nil, models: ->(_) {}).inflate(node) { :residual }).to eq(:residual)
  end

  it 'rejects an unknown table version' do
    expect { described_class.from_table(table.merge('version' => 2), models: ->(_) {}) }
      .to raise_error(ArgumentError, /version/)
  end
end
