# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/html'

RSpec.describe 'HTML frontmatter integration' do
  let(:adoc_text) do
    <<~ADOC
      ---
      author: Jane Doe
      date: 2026-06-14
      description: A test doc
      subject: Schemas
      tags:
        - foo
        - bar
      $schema: https://example.com/schema.json
      ---
      = Hello

      World.
    ADOC
  end

  let(:core) { Coradoc::AsciiDoc.parse_to_core(adoc_text) }

  describe 'Coradoc::Html::FrontmatterMeta' do
    let(:block) { core.children.first }

    it 'extracts known fields into Meta structs' do
      result = Coradoc::Html::FrontmatterMeta.extract(block)
      names = result[:metas].map(&:name)

      expect(names).to include('author', 'description', 'date', 'subject', 'keywords')
      author_meta = result[:metas].find { |m| m.name == 'author' }
      expect(author_meta.content).to eq('Jane Doe')
      keywords_meta = result[:metas].find { |m| m.name == 'keywords' }
      expect(keywords_meta.content).to eq('foo, bar')
    end

    it 'extracts $schema into a LinkTag' do
      result = Coradoc::Html::FrontmatterMeta.extract(block)
      expect(result[:links].first.rel).to eq('schema.dublin_core')
      expect(result[:links].first.href).to eq('https://example.com/schema.json')
    end

    it 'returns empty arrays for nil' do
      result = Coradoc::Html::FrontmatterMeta.extract(nil)
      expect(result[:metas]).to eq([])
      expect(result[:links]).to eq([])
      expect(result[:title]).to be_nil
    end
  end

  describe 'Coradoc::Html.serialize' do
    let(:html) { Coradoc::Html.serialize(core, layout: :static) }

    it 'emits meta tags for known frontmatter fields' do
      expect(html).to include('<meta name="author" content="Jane Doe">')
      expect(html).to include('<meta name="date" content="2026-06-14">')
      expect(html).to include('<meta name="description" content="A test doc">')
      expect(html).to include('<meta name="subject" content="Schemas">')
      expect(html).to include('<meta name="keywords" content="foo, bar">')
    end

    it 'emits a <link> tag for $schema' do
      expect(html).to include('<link rel="schema.dublin_core" href="https://example.com/schema.json">')
    end

    it 'uses the document title in <title>' do
      expect(html).to include('<title>Hello</title>')
    end
  end
end
