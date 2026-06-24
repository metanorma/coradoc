# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Frontmatter cross-format integration', type: :integration do
  let(:yaml_frontmatter) do
    <<~YAML.strip
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
    YAML
  end

  let(:adoc_text) { "---\n#{yaml_frontmatter}\n---\n\n= Hello\n\nWorld.\n" }
  let(:md_text)   { "---\n#{yaml_frontmatter}\n---\n\n# Hello\n\nWorld.\n" }

  describe 'AsciiDoc → CoreModel → Markdown' do
    it 'preserves frontmatter keys and values through YAML round-trip' do
      core = Coradoc::AsciiDoc.parse_to_core(adoc_text)

      fm = core.children.first
      expect(fm).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(fm.schema).to eq('https://example.com/s.json')
      expect(fm.data['title']).to eq('Release Notes')
      expect(fm.data['date']).to eq(Date.new(2024, 7, 22))
      expect(fm.data['count']).to eq(42)
      expect(fm.data['flag']).to be true
      expect(fm.data['tags']).to eq(%w[foo bar])
      expect(fm.data['author']).to eq(
        'name' => 'Alice', 'email' => 'alice@example.com'
      )

      md_doc = Coradoc::Markdown.from_core_model(core)
      md_out = Coradoc::Markdown.serialize(md_doc)
      expect(md_out).to start_with("---\n")
      expect(md_out).to include('title: Release Notes')
      expect(md_out).to include('date: 2024-07-22')

      md_core = Coradoc::Markdown.to_core_model(md_doc)
      fm2 = md_core.children.first
      expect(fm2.schema).to eq(fm.schema)
      expect(fm2.data.keys).to eq(fm.data.keys)
      expect(fm2.data['date']).to eq(Date.new(2024, 7, 22))
      expect(fm2.data['count']).to eq(42)
      expect(fm2.data['tags']).to eq(%w[foo bar])
    end
  end

  describe 'Markdown → CoreModel → AsciiDoc' do
    it 'round-trips frontmatter in the reverse direction' do
      md_doc = Coradoc::Markdown.parse(md_text)
      core = Coradoc::Markdown.to_core_model(md_doc)

      fm = core.children.first
      expect(fm).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(fm.data['title']).to eq('Release Notes')
      expect(fm.data['date']).to eq(Date.new(2024, 7, 22))
      expect(fm.data['count']).to eq(42)

      adoc_doc = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(core)
      adoc_out = Coradoc::AsciiDoc::Serializer.serialize(adoc_doc)
      expect(adoc_out).to start_with("---\n")
      expect(adoc_out).to include('title: Release Notes')
    end
  end

  describe 'Coradoc.convert end-to-end', if: defined?(Coradoc::AsciiDoc) && defined?(Coradoc::Markdown) do
    it 'converts AsciiDoc frontmatter to Markdown via CoreModel' do
      md = Coradoc.convert(adoc_text, from: :asciidoc, to: :markdown)
      expect(md).to start_with("---\n")
      expect(md).to include('title: Release Notes')
      expect(md).to include('date: 2024-07-22')

      md_core = Coradoc::Markdown.to_core_model(Coradoc::Markdown.parse(md))
      fm = md_core.children.first
      expect(fm).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(fm.data['count']).to eq(42)
      expect(fm.data['tags']).to eq(%w[foo bar])
    end
  end

  describe 'CoreModel → Mirror → CoreModel', if: defined?(Coradoc::Mirror) do
    it 'survives JSON round-trip preserving Date as a typed Date' do
      core = Coradoc::AsciiDoc.parse_to_core(adoc_text)
      original_fm = core.children.first

      mirror_doc = Coradoc::Mirror.transform(core)
      json = JSON.generate(mirror_doc.to_hash)

      parsed = JSON.parse(json)
      frontmatter_node = parsed.dig('content', 0)
      expect(frontmatter_node['type']).to eq('frontmatter')
      expect(frontmatter_node['attrs']['schema']).to eq('https://example.com/s.json')

      # Typed tree: attrs.entries is a list of {key, value} pairs.
      entries = frontmatter_node['attrs']['entries']
      by_key = entries.each_with_object({}) { |e, h| h[e['key']] = e['value'] }
      expect(by_key['date']['value_type']).to eq('date')
      expect(by_key['date']['date_value']).to eq('2024-07-22')
      expect(by_key['count']['value_type']).to eq('integer')
      expect(by_key['count']['integer_value']).to eq(42)
      expect(by_key['tags']['value_type']).to eq('array')
      expect(by_key['tags']['items'].map { |v| v['string_value'] }).to eq(%w[foo bar])

      rebuilt_node = Coradoc::Mirror.from_hash(parsed)
      rebuilt = Coradoc::Mirror::MirrorToCoreModel.new.call(rebuilt_node)
      rebuilt_fm = rebuilt.children.find { |c| c.is_a?(Coradoc::CoreModel::FrontmatterBlock) }
      expect(rebuilt_fm.schema).to eq(original_fm.schema)
      expect(rebuilt_fm.data['title']).to eq('Release Notes')
      expect(rebuilt_fm.data['date']).to eq(Date.new(2024, 7, 22))
      expect(rebuilt_fm.data['count']).to eq(42)
      expect(rebuilt_fm.data['tags']).to eq(%w[foo bar])
    end
  end
end
