# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Commit ee92b2b extracted two parameterised builders
# (`constrained_mark`, `unconstrained_mark`) and a registry
# (`INLINE_RULE_ORDER`) from the previously hand-rolled inline
# alternation. These specs lock in the invariants the builders
# depend on:
#
#  * INLINE_RULE_ORDER is the single source of truth for inline
#    alternation. Order is load-bearing — typographic_quote must
#    precede monospace_constrained, and each unconstrained must
#    precede its constrained sibling.
#  * The constrained builder adds a `marker.absent?` guard on both
#    ends so single-marker constrained never matches when a
#    double-marker unconstrained is intended.
#  * The unconstrained builder allows newlines in the content
#    (Bug 15B parity across all four marks).
RSpec.describe 'Parser::Inline rule builders', :asciidoc do
  let(:order) { Coradoc::AsciiDoc::Parser::Inline::INLINE_RULE_ORDER }

  describe 'INLINE_RULE_ORDER invariants' do
    it 'is frozen (load-bearing — adding rules is append-only)' do
      expect(order).to be_frozen
    end

    it 'places typographic_quote before monospace_constrained (Bug 14)' do
      expect(order.index(:typographic_quote))
        .to be < order.index(:monospace_constrained)
    end

    %i[bold italic highlight monospace].each do |mark|
      it "places #{mark}_unconstrained before #{mark}_constrained" do
        unconstrained = order.index(:"#{mark}_unconstrained")
        constrained = order.index(:"#{mark}_constrained")
        expect(unconstrained).to be < constrained
      end
    end

    it 'includes superscript and subscript' do
      expect(order).to include(:superscript, :subscript)
    end

    it 'includes hard_line_break as the final rule' do
      expect(order.last).to eq(:hard_line_break)
    end
  end

  describe 'constrained_mark builder — alternation precedence' do
    def parse_inline(adoc)
      Coradoc.parse(adoc, format: :asciidoc).children.first
    end

    it '`**bold**` produces BoldElement (unconstrained wins via ordering)' do
      bold = parse_inline('**bold**').children.first
      expect(bold).to be_a(Coradoc::CoreModel::BoldElement)
      expect(bold.content).to eq('bold')
    end

    it '`*bold*` produces BoldElement (constrained, single markers)' do
      bold = parse_inline('*bold*').children.first
      expect(bold).to be_a(Coradoc::CoreModel::BoldElement)
      expect(bold.content).to eq('bold')
    end

    it 'constrained marks do not span paragraph breaks (reject_paragraph_break)' do
      # `*foo\n\nbar*` — the constrained builder's `\n\n.absent?` guard
      # blocks the match, so the asterisks emit as text.
      para = parse_inline("*foo\n\nbar*")
      bolds = para.children.select { |c| c.is_a?(Coradoc::CoreModel::BoldElement) }
      expect(bolds).to be_empty
    end
  end

  describe 'unconstrained_mark builder — newline parity (Bug 15B)' do
    def parse_inline(adoc)
      Coradoc.parse(adoc, format: :asciidoc).children.first
    end

    {
      Coradoc::CoreModel::BoldElement => '**',
      Coradoc::CoreModel::ItalicElement => '__',
      Coradoc::CoreModel::HighlightElement => '##',
      Coradoc::CoreModel::MonospaceElement => '``'
    }.each_pair do |klass, marker|
      it "#{klass.name.split('::').last} spans newlines via #{marker}…#{marker}" do
        mark = parse_inline("#{marker}multi\nline#{marker}").children.first
        expect(mark).to be_a(klass)
        expect(mark.content).to eq("multi\nline")
      end
    end
  end
end
