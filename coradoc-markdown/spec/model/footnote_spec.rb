# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::Footnote do
  describe '.new' do
    it 'creates a footnote with id and content' do
      fn = described_class.new(id: '1', content: 'This is a footnote')

      expect(fn.id).to eq('1')
      expect(fn.content).to eq('This is a footnote')
    end
  end
end

RSpec.describe Coradoc::Markdown::FootnoteReference do
  describe '.new' do
    it 'creates a footnote reference with id' do
      ref = described_class.new(id: 'fn')

      expect(ref.id).to eq('fn')
    end
  end

  describe '#to_md' do
    it 'serializes to Markdown format' do
      ref = described_class.new(id: '1')

      expect(ref.to_md).to eq('[^1]')
    end
  end
end

RSpec.describe 'Footnote Parsing' do
  let(:parser) { Coradoc::Markdown::Parser::BlockParser.new }

  describe 'footnote definition' do
    it 'parses a simple footnote definition' do
      result = parser.parse("[^fn]: Some footnote text\n")

      expect(result).to be_an(Array)
      expect(result.first).to have_key(:fn_id)
      expect(result.first).to have_key(:fn_content)
    end

    it 'parses a footnote definition with continuation' do
      result = parser.parse("[^fn]: First line\n    Second line\n")

      expect(result).to be_an(Array)
      expect(result.first).to have_key(:fn_id)
    end
  end

  describe 'footnote model transformation' do
    it 'transforms AST to Footnote model' do
      doc = Coradoc::Markdown.parse("Some text\n\n[^fn]: A footnote\n")

      expect(doc.blocks).to be_an(Array)
      expect(doc.blocks.length).to eq(2)
      expect(doc.blocks.first).to be_a(Coradoc::Markdown::Paragraph)
      expect(doc.blocks.last).to be_a(Coradoc::Markdown::Footnote)
      expect(doc.blocks.last.id).to eq('fn')
      expect(doc.blocks.last.content).to eq('A footnote')
    end

    it 'handles multiline footnote content' do
      doc = Coradoc::Markdown.parse("[^fn]: First line\n    Second line\n")

      expect(doc.blocks.first).to be_a(Coradoc::Markdown::Footnote)
      expect(doc.blocks.first.content).to include('First line')
    end
  end
end

RSpec.describe 'AstProcessor footnote references' do
  describe '.extract_inline_elements' do
    it 'extracts footnote references from text' do
      result = Coradoc::Markdown::Parser::AstProcessor.extract_inline_elements('See [^1] for details')

      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
      expect(result[0]).to eq('See ')
      expect(result[1]).to eq({ fn_ref: '1' })
      expect(result[2]).to eq(' for details')
    end

    it 'handles multiple footnote references' do
      result = Coradoc::Markdown::Parser::AstProcessor.extract_inline_elements('See [^1] and [^2]')

      expect(result).to be_an(Array)
      expect(result.length).to eq(4)
      expect(result[1]).to eq({ fn_ref: '1' })
      expect(result[3]).to eq({ fn_ref: '2' })
    end

    it 'returns original text if no references' do
      result = Coradoc::Markdown::Parser::AstProcessor.extract_inline_elements('No references here')

      expect(result).to eq('No references here')
    end
  end

  describe '.apply_typography' do
    it 'converts -- to en-dash' do
      result = Coradoc::Markdown::Parser::AstProcessor.apply_typography('pages 10--20')
      expect(result).to eq('pages 10–20')
    end

    it 'converts --- to em-dash' do
      result = Coradoc::Markdown::Parser::AstProcessor.apply_typography('Yes---that is correct')
      expect(result).to eq('Yes—that is correct')
    end

    it 'converts ... to ellipsis' do
      result = Coradoc::Markdown::Parser::AstProcessor.apply_typography('And then...')
      expect(result).to eq('And then…')
    end
  end
end
