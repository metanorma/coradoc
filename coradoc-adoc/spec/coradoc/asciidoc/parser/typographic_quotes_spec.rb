# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# AsciiDoc's typographic quote syntax (`` "` `` / `` `" `` / `` '` `` /
# `` `' ``) substitutes straight ASCII quotes with curly Unicode quotes.
# Before this fix, the backtick in the 2-char pattern was parsed as
# constrained monospace, leaving the surrounding quote as a straight
# literal and wrapping the quoted text in a spurious `code` mark.
# When the quoted text contained an inline mark (`__italic__`,
# `**bold**`), the inner mark was never recognised and the entire
# span — including the marker characters — was absorbed as raw
# content of the misidentified monospace.
#
# Coverage below locks in:
#   * Each of the four patterns emits the correct Unicode char.
#   * Inner inline marks (italic, bold) are recognised inside quotes.
#   * Plain monospace (`` `...` ``) still works when not preceded
#     by a quote char.
RSpec.describe 'Typographic quote substitution', :asciidoc do
  def first_paragraph_children(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first.children
  end

  describe 'curly double quotes' do
    let(:children) { first_paragraph_children('He said "`hello world`" to me.') }

    it 'emits U+201C for the opener' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('“')
    end

    it 'emits U+201D for the closer' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('”')
    end

    it 'does not wrap the inner text in a MonospaceElement' do
      expect(children.none?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end

    it 'preserves the inner text as plain text' do
      texts = children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : '' }
      expect(texts.join).to include('hello world')
    end
  end

  describe 'curly single quotes' do
    let(:children) { first_paragraph_children("She replied '`hi there`'.") }

    it 'emits U+2018 for the opener' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('‘')
    end

    it 'emits U+2019 for the closer' do
      expect(children.map { |c| c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : nil })
        .to include('’')
    end
  end

  describe 'inline marks inside curly double quotes' do
    let(:children) { first_paragraph_children('"`__important__`" was the key word.') }

    it 'recognises __italic__ as ItalicElement' do
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic).not_to be_nil
    end

    it 'produces correct text in the italic element' do
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic.content).to include('important')
    end

    it 'does not leave raw __ markers in the output' do
      combined = children.flat_map do |c|
        c.is_a?(Coradoc::CoreModel::TextContent) ? c.text : c.content.to_s
      end.join
      expect(combined).not_to include('__')
    end
  end

  describe 'inline marks inside curly double quotes (bold)' do
    let(:children) { first_paragraph_children('"`**critical**`" was another.') }

    it 'recognises **bold** as BoldElement', :aggregate_failures do
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold).not_to be_nil
      expect(bold.content).to include('critical')
    end
  end

  describe 'plain monospace still works' do
    let(:children) { first_paragraph_children('Type `code` here.') }

    it 'wraps plain `code` in a MonospaceElement', :aggregate_failures do
      mono = children.find { |c| c.is_a?(Coradoc::CoreModel::MonospaceElement) }
      expect(mono).not_to be_nil
      expect(mono.content).to include('code')
    end
  end

  describe 'unconstrained marks still work' do
    it '**bold** produces BoldElement' do
      children = first_paragraph_children('This is **bold** text.')
      bold = children.find { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bold.content).to include('bold')
    end

    it '__italic__ produces ItalicElement' do
      children = first_paragraph_children('This is __italic__ text.')
      italic = children.find { |c| c.is_a?(Coradoc::CoreModel::ItalicElement) }
      expect(italic.content).to include('italic')
    end

    it '``code`` produces MonospaceElement' do
      children = first_paragraph_children('This is ``code`` text.')
      mono = children.find { |c| c.is_a?(Coradoc::CoreModel::MonospaceElement) }
      expect(mono.content).to include('code')
    end
  end
end
