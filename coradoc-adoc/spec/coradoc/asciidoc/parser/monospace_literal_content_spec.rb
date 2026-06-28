# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Asciidoctor treats the content of a constrained monospace span (`` `…` ``)
# as an inline literal: nested markup syntax like `<<…>>` xrefs, `link:…`
# links, or even unconstrained `` ``…`` `` monospace pairs must survive as
# literal text rather than being re-interpreted by inline rules.
#
# Before this fix, `monospace_constrained` only allowed `[^`\n]+` as content,
# so any inner backtick terminated the match attempt. The closing-backtick
# lookahead then failed on the inner `` `` `` pair, the whole rule
# backtracked, and the `<<…>>` payload fired `cross_reference` with the
# backticks glued onto the xref target.
#
# Coverage below locks in the literal-content behaviour for the reported
# xref case and several neighbours (links, multiple inner pairs, simple
# monospace still parsing correctly).
RSpec.describe 'Constrained monospace literal content', :asciidoc do
  def first_inline(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first.children.first
  end

  def monospace_with(content)
    Coradoc::CoreModel::MonospaceElement.new(content: content)
  end

  describe 'simple monospace (regression guard)' do
    it 'parses `hello` as a single MonospaceElement' do
      node = first_inline('`hello`')
      expect(node).to be_a(Coradoc::CoreModel::MonospaceElement)
    end

    it 'preserves the inner text' do
      expect(first_inline('`hello`').content).to eq('hello')
    end
  end

  describe 'xref syntax inside backticks' do
    it 'does not fire cross_reference for `<<target>>`' do
      node = first_inline('`<<target>>`')
      expect(node).to be_a(Coradoc::CoreModel::MonospaceElement)
    end

    it 'preserves the literal `<<target>>` payload as content' do
      expect(first_inline('`<<target>>`').content).to eq('<<target>>')
    end
  end

  describe 'the reported bug: xref with inner unconstrained monospace' do
    let(:adoc) { '`<<``ricepotentialmilling``>>`' }

    it 'produces a single MonospaceElement', :aggregate_failures do
      node = first_inline(adoc)
      expect(node).to be_a(Coradoc::CoreModel::MonospaceElement)
      expect(node.content).to eq('<<``ricepotentialmilling``>>')
    end

    it 'does not emit a CrossReferenceElement anywhere in the paragraph' do
      doc = Coradoc.parse(adoc, format: :asciidoc)
      flat = doc.children.flat_map(&:children)
      expect(flat.none?(Coradoc::CoreModel::CrossReferenceElement)).to be(true)
    end
  end

  describe 'multiple inner unconstrained pairs' do
    it 'treats each `` pair as inner content' do
      expect(first_inline('`a``b``c`').content).to eq('a``b``c')
    end

    it 'handles three inner pairs' do
      expect(first_inline('`a``b``c``d`').content).to eq('a``b``c``d')
    end
  end

  describe 'other inline markup inside backticks' do
    it 'does not fire link: inside backticks', :aggregate_failures do
      node = first_inline('`link:https://example.com[label]`')
      expect(node).to be_a(Coradoc::CoreModel::MonospaceElement)
      expect(node.content).to eq('link:https://example.com[label]')
    end

    it 'does not fire footnote: inside backticks' do
      node = first_inline('`footnote:[text]`')
      expect(node).to be_a(Coradoc::CoreModel::MonospaceElement)
    end
  end

  describe 'equivalent output for in-memory and serialized forms' do
    it 'matches the explicit MonospaceElement construction' do
      parsed = first_inline('`<<``x``>>`')
      expected = monospace_with('<<``x``>>')
      expect(parsed.content).to eq(expected.content)
    end
  end
end
