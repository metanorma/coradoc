# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'

RSpec.describe 'AsciiDoc frontmatter round-trip' do
  let(:frontmatter_yml) do
    <<~YAML.strip
      author: Jane Doe
      date: 2026-06-14
      tags:
        - foo
        - bar
    YAML
  end

  let(:adoc_body) { "= Hello\n\nWorld.\n" }
  let(:adoc_text) { "---\n#{frontmatter_yml}\n---\n\n#{adoc_body}" }

  it 'Asciidoc -> CoreModel prepends a FrontmatterBlock' do
    doc = Coradoc::AsciiDoc.parse(adoc_text)
    core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)

    expect(core).to be_a(Coradoc::CoreModel::DocumentElement)
    expect(core.children.first).to be_a(Coradoc::CoreModel::FrontmatterBlock)

    block = core.children.first
    expect(block.data['author']).to eq('Jane Doe')
    expect(block.data['date']).to eq(Date.new(2026, 6, 14))
    expect(block.data['tags']).to eq(%w[foo bar])
  end

  it 'CoreModel -> AsciiDoc extracts FrontmatterBlock back to frontmatter text' do
    doc = Coradoc::AsciiDoc.parse(adoc_text)
    core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
    back = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)

    expect(back.frontmatter).to include('author: Jane Doe')
    expect(back.frontmatter).to include('date: 2026-06-14')
  end

  it 'Asciidoc serializer emits `---` delimiters when frontmatter present' do
    doc = Coradoc::AsciiDoc.parse(adoc_text)
    core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
    back = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)
    serialized = Coradoc::AsciiDoc::Serializer.serialize(back)

    expect(serialized).to start_with("---\n")
    expect(serialized).to include('author: Jane Doe')
    expect(serialized).to include("\n---\n\n")
  end

  it 'documents without frontmatter round-trip cleanly without delimiters' do
    doc = Coradoc::AsciiDoc.parse("= Plain Title\n\nBody.\n")
    core = Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
    back = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)
    serialized = Coradoc::AsciiDoc::Serializer.serialize(back)

    expect(serialized).not_to start_with("---\n")
    expect(back.frontmatter).to be_nil
  end
end
