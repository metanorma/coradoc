# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Mirror::Node do
  describe 'construction' do
    it 'creates a basic node with type' do
      node = described_class.new(type: 'custom')
      expect(node.type).to eq('custom')
    end

    it 'uses PM_TYPE as default type' do
      node = described_class.new
      expect(node.type).to eq('node')
    end
  end

  describe 'typed attributes' do
    it 'Document has title and id accessors under attrs' do
      doc = described_class::Document.new(
        attrs: described_class::Document::Attrs.new(title: 'My Doc', id: 'doc-1')
      )
      expect(doc.attrs.title).to eq('My Doc')
      expect(doc.attrs.id).to eq('doc-1')
    end

    it 'Section has title, id, level accessors under attrs' do
      section = described_class::Section.new(
        attrs: described_class::Section::Attrs.new(title: 'Intro', id: 's1', level: 2)
      )
      expect(section.attrs.title).to eq('Intro')
      expect(section.attrs.id).to eq('s1')
      expect(section.attrs.level).to eq(2)
    end

    it 'CodeBlock has language, title, passthrough accessors under attrs' do
      code = described_class::CodeBlock.new(
        attrs: described_class::CodeBlock::Attrs.new(language: 'ruby', title: 'Example', passthrough: true)
      )
      expect(code.attrs.language).to eq('ruby')
      expect(code.attrs.title).to eq('Example')
      expect(code.attrs.passthrough).to be true
    end

    it 'Image has src, alt, caption, width, height, role accessors under attrs' do
      img = described_class::Image.new(
        attrs: described_class::Image::Attrs.new(
          src: 'img.png', alt: 'Alt', caption: 'Cap', width: '100', role: 'figure'
        )
      )
      expect(img.attrs.src).to eq('img.png')
      expect(img.attrs.alt).to eq('Alt')
      expect(img.attrs.caption).to eq('Cap')
      expect(img.attrs.width).to eq('100')
      expect(img.attrs.height).to be_nil
      expect(img.attrs.role).to eq('figure')
    end

    it 'TableCell has colspan, rowspan, alignment, header accessors under attrs' do
      cell = described_class::TableCell.new(
        attrs: described_class::TableCell::Attrs.new(colspan: 2, header: true, alignment: 'center')
      )
      expect(cell.attrs.colspan).to eq(2)
      expect(cell.attrs.header).to be true
      expect(cell.attrs.alignment).to eq('center')
      expect(cell.attrs.rowspan).to be_nil
    end
  end

  describe 'serialization' do
    it 'serializes to hash with only non-empty fields' do
      node = described_class.new(type: 'paragraph')
      expect(node.to_hash).to eq({ 'type' => 'paragraph' })
    end

    it 'includes typed attrs when set' do
      node = described_class::Header.new(
        attrs: described_class::Header::Attrs.new(level: 1)
      )
      expect(node.to_hash).to eq({
                                   'type' => 'floating_title',
                                   'attrs' => { 'level' => 1 }
                                 })
    end

    it 'omits nil attrs' do
      node = described_class::Section.new(
        attrs: described_class::Section::Attrs.new(title: 'Intro')
      )
      expect(node.to_hash).to eq({
                                   'type' => 'section',
                                   'attrs' => { 'title' => 'Intro' }
                                 })
    end

    it 'includes content when present' do
      child = described_class::Text.new(text: 'hello')
      node = described_class::Paragraph.new(content: [child])
      hash = node.to_hash
      expect(hash['content']).to be_an(Array)
      expect(hash['content'].length).to eq(1)
    end

    it 'includes marks when present' do
      mark = Coradoc::Mirror::Mark::Bold.new
      node = described_class::Text.new(text: 'bold', marks: [mark])
      hash = node.to_hash
      expect(hash['marks']).to be_an(Array)
    end

    it 'serializes to JSON via to_hash' do
      node = described_class::Paragraph.new
      json = JSON.generate(node.to_hash)
      expect(JSON.parse(json)).to eq({ 'type' => 'paragraph' })
    end

    it 'serializes to pretty JSON' do
      node = described_class::Paragraph.new
      json = JSON.pretty_generate(node.to_hash)
      expect(json).to include("\n")
    end

    it 'serializes to YAML' do
      node = described_class::Section.new(
        attrs: described_class::Section::Attrs.new(id: 'p1')
      )
      yaml = YAML.dump(node.to_hash)
      parsed = YAML.safe_load(yaml)
      expect(parsed['type']).to eq('section')
      expect(parsed['attrs']['id']).to eq('p1')
    end
  end

  describe 'deserialization' do
    it 'reconstructs typed nodes from hash via Mirror.from_hash' do
      hash = {
        'type' => 'section',
        'attrs' => { 'title' => 'Intro', 'level' => 1 },
        'content' => [
          { 'type' => 'paragraph', 'content' => [
            { 'type' => 'text', 'text' => 'Hello' }
          ] }
        ]
      }

      node = Coradoc::Mirror.from_hash(hash)
      expect(node).to be_a(described_class::Section)
      expect(node.attrs.title).to eq('Intro')
      expect(node.attrs.level).to eq(1)
      expect(node.content.length).to eq(1)

      para = node.content.first
      expect(para).to be_a(described_class::Paragraph)
      expect(para.content.first).to be_a(described_class::Text)
      expect(para.content.first.text).to eq('Hello')
    end

    it 'raises on unknown types via Mirror.from_hash' do
      hash = { 'type' => 'unknown_custom_type' }
      expect { Coradoc::Mirror.from_hash(hash) }.to raise_error(Coradoc::Mirror::Error)
    end
  end

  describe 'text_content' do
    it 'returns empty string for node with no content' do
      node = described_class.new
      expect(node.text_content).to eq('')
    end

    it 'collects text from descendants' do
      text = described_class::Text.new(text: 'Hello ')
      text2 = described_class::Text.new(text: 'World')
      para = described_class::Paragraph.new(content: [text, text2])
      expect(para.text_content).to eq('Hello World')
    end
  end

  describe 'node type subclasses' do
    it 'registers all subclasses in TYPE_TO_CLASS map' do
      expect(described_class::TYPE_TO_CLASS['doc']).to eq(described_class::Document.name)
      expect(described_class::TYPE_TO_CLASS['paragraph']).to eq(described_class::Paragraph.name)
      expect(described_class::TYPE_TO_CLASS['floating_title']).to eq(described_class::Header.name)
      expect(described_class::TYPE_TO_CLASS['sourcecode']).to eq(described_class::CodeBlock.name)
      expect(described_class::TYPE_TO_CLASS['quote']).to eq(described_class::Blockquote.name)
      expect(described_class::TYPE_TO_CLASS['bullet_list']).to eq(described_class::BulletList.name)
      expect(described_class::TYPE_TO_CLASS['ordered_list']).to eq(described_class::OrderedList.name)
      expect(described_class::TYPE_TO_CLASS['list_item']).to eq(described_class::ListItem.name)
      expect(described_class::TYPE_TO_CLASS['image']).to eq(described_class::Image.name)
      expect(described_class::TYPE_TO_CLASS['table']).to eq(described_class::Table.name)
      expect(described_class::TYPE_TO_CLASS['section']).to eq(described_class::Section.name)
      expect(described_class::TYPE_TO_CLASS['admonition']).to eq(described_class::Admonition.name)
    end

    it 'Text node has text attribute' do
      node = described_class::Text.new(text: 'Hello')
      expect(node.text).to eq('Hello')
      expect(node.to_hash['text']).to eq('Hello')
      expect(node.text_content).to eq('Hello')
    end

    it 'Text node deserializes with marks' do
      hash = {
        'type' => 'text',
        'text' => 'bold text',
        'marks' => [{ 'type' => 'strong' }]
      }
      node = described_class::Text.from_hash(hash)
      expect(node.text).to eq('bold text')
      expect(node.marks.length).to eq(1)
      expect(node.marks.first).to be_a(Coradoc::Mirror::Mark::Bold)
    end

    it 'round-trips through serialization' do
      doc = described_class::Document.new(
        attrs: described_class::Document::Attrs.new(title: 'Test'),
        content: [
          described_class::Section.new(
            attrs: described_class::Section::Attrs.new(level: 1, title: 'Intro'),
            content: [
              described_class::Paragraph.new(
                content: [
                  described_class::Text.new(
                    text: 'Hello ',
                    marks: [Coradoc::Mirror::Mark::Bold.new]
                  ),
                  described_class::Text.new(text: 'world')
                ]
              )
            ]
          )
        ]
      )

      json = JSON.pretty_generate(doc.to_hash)
      parsed = Coradoc::Mirror.from_hash(JSON.parse(json))

      expect(parsed).to be_a(described_class::Document)
      expect(parsed.attrs.title).to eq('Test')
      expect(parsed.content.length).to eq(1)
      section = parsed.content.first
      expect(section).to be_a(described_class::Section)
      expect(section.content.first.content.first.marks.first).to be_a(Coradoc::Mirror::Mark::Bold)
    end
  end

  describe 'Admonition rename' do
    it 'emits admonition_type as attrs.type on the wire' do
      node = described_class::Admonition.new(
        attrs: described_class::Admonition::Attrs.new(admonition_type: 'note')
      )
      hash = node.to_hash
      expect(hash['type']).to eq('admonition')
      expect(hash['attrs']['type']).to eq('note')
      expect(hash['attrs']).not_to have_key('admonition_type')
    end

    it 'round-trips the rename through from_hash' do
      hash = { 'type' => 'admonition', 'attrs' => { 'type' => 'tip' } }
      node = described_class::Admonition.from_hash(hash)
      expect(node.attrs.admonition_type).to eq('tip')
    end
  end
end
