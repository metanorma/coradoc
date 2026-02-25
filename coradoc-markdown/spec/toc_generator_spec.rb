# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/markdown'
require 'coradoc/markdown/toc_generator'

RSpec.describe Coradoc::Markdown::TocGenerator do
  let(:parser) { Coradoc::Markdown::Parser::BlockParser.new }

  describe '.generate' do
    it 'generates TOC from simple document' do
      doc = Coradoc::Markdown.parse("# Heading 1\n\n## Heading 2\n\n### Heading 3")

      toc = described_class.generate(doc)

      expect(toc).not_to be_nil
      expect(toc.children.length).to eq(1)
      expect(toc.children.first.text).to eq('Heading 1')
    end

    it 'returns nil for empty document' do
      doc = Coradoc::Markdown.parse("Just some text\n\nNo headings")

      toc = described_class.generate(doc)

      expect(toc).to be_nil
    end

    it 'handles nested headings correctly' do
      doc = Coradoc::Markdown.parse("# H1\n\n## H2\n\n### H3\n\n## H2b")

      toc = described_class.generate(doc)

      expect(toc.children.length).to eq(1)
      h1 = toc.children.first
      expect(h1.text).to eq('H1')
      expect(h1.children.length).to eq(2)
      expect(h1.children.first.text).to eq('H2')
      expect(h1.children.first.children.first.text).to eq('H3')
      expect(h1.children.last.text).to eq('H2b')
    end
  end

  describe '.generate_markdown' do
    it 'generates markdown formatted TOC' do
      doc = Coradoc::Markdown.parse("# First\n\n## Second")

      md = described_class.generate_markdown(doc)

      expect(md).to include('* [First](#first)')
      expect(md).to include('  * [Second](#second)')
    end

    it 'generates empty string for document without headings' do
      doc = Coradoc::Markdown.parse('Paragraph text')

      md = described_class.generate_markdown(doc)

      expect(md).to eq('')
    end
  end

  describe '.generate_array' do
    it 'generates array structure from document' do
      doc = Coradoc::Markdown.parse("# Title\n\n## Subtitle")

      arr = described_class.generate_array(doc)

      expect(arr).to be_an(Array)
      expect(arr.first[:text]).to eq('Title')
      expect(arr.first[:children].first[:text]).to eq('Subtitle')
    end
  end

  describe 'with options' do
    it 'respects min_level option' do
      doc = Coradoc::Markdown.parse("# H1\n\n## H2\n\n### H3")

      toc = described_class.generate(doc, min_level: 2)

      expect(toc.children.first.text).to eq('H2')
    end

    it 'respects max_level option' do
      doc = Coradoc::Markdown.parse("# H1\n\n## H2\n\n### H3")

      toc = described_class.generate(doc, max_level: 2)

      expect(toc.children.first.children.first.children).to be_empty
    end

    it 'adds section numbers when numbered: true' do
      doc = Coradoc::Markdown.parse("# First\n\n## Second\n\n## Third")

      toc = described_class.generate(doc, numbered: true, min_level: 1)

      expect(toc.children.first.number).to eq('1')
      expect(toc.children.first.children.first.number).to eq('1.1')
      expect(toc.children.first.children.last.number).to eq('1.2')
    end
  end

  describe 'Entry' do
    describe '#to_markdown' do
      it 'formats entry as markdown list' do
        entry = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'my-heading',
          text: 'My Heading',
          level: 1
        )

        expect(entry.to_markdown).to eq("* [My Heading](#my-heading)\n")
      end

      it 'includes children with proper indentation' do
        parent = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'parent',
          text: 'Parent',
          level: 1
        )
        child = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'child',
          text: 'Child',
          level: 2
        )
        parent.children << child

        md = parent.to_markdown
        expect(md).to include('* [Parent](#parent)')
        expect(md).to include('  * [Child](#child)')
      end

      it 'includes number prefix when present' do
        entry = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'heading',
          text: 'Heading',
          level: 1,
          number: '1.2.3'
        )

        expect(entry.to_markdown).to include('* 1.2.3 [Heading](#heading)')
      end
    end

    describe '#to_h' do
      it 'converts entry to hash' do
        entry = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'test',
          text: 'Test',
          level: 1,
          number: '1'
        )

        result = entry.to_h

        expect(result).to eq({ id: 'test', text: 'Test', level: 1, number: '1' })
      end

      it 'includes nested children' do
        parent = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'parent',
          text: 'Parent',
          level: 1
        )
        child = Coradoc::Markdown::TocGenerator::Entry.new(
          id: 'child',
          text: 'Child',
          level: 2
        )
        parent.children << child

        result = parent.to_h

        expect(result[:children]).to be_an(Array)
        expect(result[:children].first[:text]).to eq('Child')
      end
    end
  end

  describe 'integration with Heading auto_id' do
    it 'uses heading auto_id for TOC links' do
      doc = Coradoc::Markdown.parse("# Hello World!\n\n## Section 2")

      toc = described_class.generate(doc)

      expect(toc.children.first.id).to eq('hello-world')
      expect(toc.children.first.children.first.id).to eq('section-2')
    end
  end
end
