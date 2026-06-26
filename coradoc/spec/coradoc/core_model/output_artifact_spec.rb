# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/core_model'

RSpec.describe Coradoc::CoreModel::OutputArtifact do
  let(:frontmatter) do
    Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'Foo' })
  end
  let(:core_document) do
    Coradoc::CoreModel::DocumentElement.new(title: 'Foo')
  end

  it 'round-trips its three typed attributes' do
    artifact = described_class.new(
      output_key: 'author/iso/ref/foo',
      frontmatter_block: frontmatter,
      core_document: core_document
    )

    expect(artifact.output_key).to eq('author/iso/ref/foo')
    expect(artifact.frontmatter_block).to eq(frontmatter)
    expect(artifact.core_document).to eq(core_document)
  end

  it 'accepts a nil for every attribute (consumer is still bootstrapping)' do
    artifact = described_class.new

    expect(artifact.output_key).to be_nil
    expect(artifact.frontmatter_block).to be_nil
    expect(artifact.core_document).to be_nil
  end

  it 'compares semantically on the three attributes' do
    a = described_class.new(output_key: 'a/b', core_document: core_document)
    b = described_class.new(output_key: 'a/b', core_document: core_document)

    expect(a.semantically_equivalent?(b)).to be(true)
  end

  it 'distinguishes by output_key' do
    a = described_class.new(output_key: 'a/b')
    b = described_class.new(output_key: 'a/c')

    expect(a.semantically_equivalent?(b)).to be(false)
  end

  it 'inherits Base.build for fluent construction' do
    artifact = described_class.build(output_key: 'x/y') do |a|
      a.frontmatter_block = frontmatter
    end

    expect(artifact.output_key).to eq('x/y')
    expect(artifact.frontmatter_block).to eq(frontmatter)
  end
end
