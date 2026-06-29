# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Inline marks nested inside other marks (e.g. `**bold \`code\`**`)
# must be recognised. Before this fix, the outer mark's content was
# captured as a flat string and the inner mark's delimiter characters
# leaked as raw text in the output.
#
# Coverage below locks in:
#   * Bold wrapping constrained code.
#   * Italic wrapping constrained code.
#   * Bold with text + code + text (multiple children).
#   * Plain bold / italic (no nesting) still produce single mark.
#   * The proper long-form `` "` ``text`` `" `` for code in curly
#     quotes works (curly + monospace + curly).
RSpec.describe 'Nested inline marks', :asciidoc do
  def first_paragraph(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  describe 'bold wrapping constrained code' do
    let(:adoc) { '**Per-repo `file.yml`**' }
    let(:para) { first_paragraph(adoc) }

    it 'produces a BoldElement' do
      expect(para.children.first).to be_a(Coradoc::CoreModel::BoldElement)
    end

    it 'BoldElement has parsed children' do
      bold = para.children.first
      expect(bold.children.length).to eq(2)
    end

    it 'first child is TextContent for "Per-repo "' do
      bold = para.children.first
      expect(bold.children[0]).to be_a(Coradoc::CoreModel::TextContent)
      expect(bold.children[0].text).to eq('Per-repo ')
    end

    it 'second child is MonospaceElement for "file.yml"' do
      bold = para.children.first
      expect(bold.children[1]).to be_a(Coradoc::CoreModel::MonospaceElement)
      expect(bold.children[1].content).to eq('file.yml')
    end
  end

  describe 'italic wrapping constrained code' do
    let(:adoc) { '__Per-repo `file.yml`__' }
    let(:para) { first_paragraph(adoc) }

    it 'produces an ItalicElement with children' do
      italic = para.children.first
      expect(italic).to be_a(Coradoc::CoreModel::ItalicElement)
      expect(italic.children.length).to eq(2)
    end

    it 'inner child is MonospaceElement' do
      italic = para.children.first
      expect(italic.children[1]).to be_a(Coradoc::CoreModel::MonospaceElement)
    end
  end

  describe 'bold with text + code + text' do
    let(:adoc) { '**a `b` c**' }
    let(:para) { first_paragraph(adoc) }

    it 'produces a BoldElement with three children' do
      bold = para.children.first
      expect(bold).to be_a(Coradoc::CoreModel::BoldElement)
      expect(bold.children.length).to eq(3)
    end

    it 'has TextContent → MonospaceElement → TextContent' do
      bold = para.children.first
      expect(bold.children[0]).to be_a(Coradoc::CoreModel::TextContent)
      expect(bold.children[1]).to be_a(Coradoc::CoreModel::MonospaceElement)
      expect(bold.children[2]).to be_a(Coradoc::CoreModel::TextContent)
    end
  end

  describe 'plain marks (no nesting)' do
    it 'plain bold produces a BoldElement with flat content' do
      bold = first_paragraph('**just bold**').children.first
      expect(bold).to be_a(Coradoc::CoreModel::BoldElement)
      expect(bold.content).to eq('just bold')
    end

    it 'plain italic produces an ItalicElement with flat content' do
      italic = first_paragraph('__just italic__').children.first
      expect(italic).to be_a(Coradoc::CoreModel::ItalicElement)
      expect(italic.content).to eq('just italic')
    end
  end

  describe 'code inside curly quotes (proper long form)' do
    let(:adoc) { '"` ``text`` `"' }
    let(:para) { first_paragraph(adoc) }

    it 'emits a curly open quote' do
      texts = para.children.map do |c|
        c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil
      end
      expect(texts).to include('“')
    end

    it 'contains a MonospaceElement for "text"', :aggregate_failures do
      mono = para.children.find { |c| c.is_a?(Coradoc::CoreModel::MonospaceElement) }
      expect(mono).not_to be_nil
      expect(mono.content).to eq('text')
    end

    it 'emits a curly close quote' do
      texts = para.children.map do |c|
        c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil
      end
      expect(texts).to include('”')
    end
  end
end
