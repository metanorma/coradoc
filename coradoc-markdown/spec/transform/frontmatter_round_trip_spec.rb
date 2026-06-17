# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown frontmatter round-trip', :aggregate_failures do
  let(:input) do
    <<~MD
      ---
      $schema: https://example.com/s.json
      title: Release Notes
      date: 2024-07-22
      count: 42
      flag: true
      tags:
        - foo
        - bar
      author:
        name: Alice
        email: alice@example.com
      ---

      # Release

      Body paragraph with **bold** text.
    MD
  end

  it 'parses frontmatter into Document#frontmatter' do
    doc = Coradoc::Markdown.parse(input)
    expect(doc.frontmatter).to include('title: Release Notes')
    expect(doc.frontmatter).to include('$schema: https://example.com/s.json')
    expect(doc.blocks.size).to be >= 2
  end

  it 'serializes frontmatter + body back to Markdown' do
    doc = Coradoc::Markdown.parse(input)
    out = Coradoc::Markdown.serialize(doc)
    expect(out).to start_with("---\n")
    expect(out).to include('$schema: https://example.com/s.json')
    expect(out).to include('title: Release Notes')
    expect(out).to include('date: 2024-07-22')
    expect(out).to include('# Release')
    expect(out).to include('Body paragraph with **bold** text.')
  end

  it 'round-trips through CoreModel preserving types' do
    doc = Coradoc::Markdown.parse(input)
    core = Coradoc::Markdown.to_core_model(doc)

    frontmatter = core.children.first
    expect(frontmatter).to be_a(Coradoc::CoreModel::FrontmatterBlock)
    expect(frontmatter.schema).to eq('https://example.com/s.json')
    expect(frontmatter.data['title']).to eq('Release Notes')
    expect(frontmatter.data['date']).to eq(Date.new(2024, 7, 22))
    expect(frontmatter.data['count']).to eq(42)
    expect(frontmatter.data['flag']).to be true
    expect(frontmatter.data['tags']).to eq(%w[foo bar])
    expect(frontmatter.data['author']).to eq(
      'name' => 'Alice', 'email' => 'alice@example.com'
    )
  end

  it 'survives Markdown → Core → Markdown → Core with stable schema' do
    doc1 = Coradoc::Markdown.parse(input)
    core1 = Coradoc::Markdown.to_core_model(doc1)
    doc2 = Coradoc::Markdown.from_core_model(core1)
    core2 = Coradoc::Markdown.to_core_model(doc2)

    fm1 = core1.children.first
    fm2 = core2.children.first
    expect(fm2.schema).to eq(fm1.schema)
    expect(fm2.data['title']).to eq(fm1.data['title'])
    expect(fm2.data['date']).to eq(fm1.data['date'])
    expect(fm2.data['count']).to eq(fm1.data['count'])
    expect(fm2.data['tags']).to eq(fm1.data['tags'])
  end

  it 'omits the frontmatter block when source has none' do
    plain = "# Just a heading\n\nBody.\n"
    doc = Coradoc::Markdown.parse(plain)
    expect(doc.frontmatter).to be_nil

    core = Coradoc::Markdown.to_core_model(doc)
    expect(core.children.first).not_to be_a(Coradoc::CoreModel::FrontmatterBlock)

    out = Coradoc::Markdown.serialize(doc)
    expect(out).not_to start_with("---\n")
    expect(out).to include('# Just a heading')
  end

  it 'produces an empty FrontmatterBlock but still parses the body when YAML is malformed' do
    malformed = <<~MD
      ---
      title: [unclosed
      ---

      # Body survives
    MD
    doc = Coradoc::Markdown.parse(malformed)
    expect(doc.frontmatter).to include('title: [unclosed')

    core = Coradoc::Markdown.to_core_model(doc)
    fm = core.children.first
    expect(fm).to be_a(Coradoc::CoreModel::FrontmatterBlock)
    expect(fm).to be_empty
    # Body content survives past the frontmatter
    expect(core.children.any? { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }).to be true
  end
end
