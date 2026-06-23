# frozen_string_literal: true

require 'spec_helper'

# Regression for BUG-xref-with-commas-quotes.md.
#
# AsciiDoc cross-references like `<<target,text>>` must convert to
# Markdown `[text](#target)`. When the text portion contains commas,
# quotes, or "clause/section" keywords, the parser was over-engineering
# it into a structured `key/delimiter/value` subtree that no transformer
# rule consumed, producing empty Markdown output.
#
# Root cause: the cross_reference parser rule split the text after the
# first comma into a structured `xref_arg` (for keywords like "clause N")
# or a generic `xref_str`, then wrapped both in `.repeat(1)`. The
# resulting array-of-hashes could not match `sequence(:xref)` in the
# transformer (Parslet's SequenceBind rejects arrays containing hashes).
#
# Fix: simplify the parser to capture everything after the first comma as
# a single `:text` string. Anything up to `>` is allowed — including
# commas, quotes, and keyword prefixes.
RSpec.describe 'Cross-reference text with commas/quotes', type: :integration do
  def to_markdown(src)
    Coradoc.serialize(
      Coradoc.parse(src + "\n", format: :asciidoc),
      to: :markdown, markdown_flavor: :vitepress
    ).strip
  end

  it 'converts a bare target xref' do
    expect(to_markdown('<<figureC-1>>')).to eq('[figureC-1](#figureC-1)')
  end

  it 'converts a simple text label' do
    expect(to_markdown('<<figureC-1,Figure 1>>')).to eq('[Figure 1](#figureC-1)')
  end

  it 'converts a clause-style label with digits' do
    expect(to_markdown('<<ISO2382,clause 2121372>>')).to eq('[clause 2121372](#ISO2382)')
  end

  it 'converts a label containing double quotes' do
    expect(to_markdown('<<ievtermbank,clause "113-01-08">>'))
      .to eq('[clause "113-01-08"](#ievtermbank)')
  end

  it 'preserves additional commas in the label' do
    expect(to_markdown('<<ISO2382,clause,section 4>>'))
      .to eq('[clause,section 4](#ISO2382)')
  end

  it 'threads the label text into CoreModel content' do
    core = Coradoc.parse("<<ISO2382,clause 2121372>>\n", format: :asciidoc)
    xref = core.children.first.children.first
    expect(xref).to be_a(Coradoc::CoreModel::CrossReferenceElement)
    expect(xref.target).to eq('ISO2382')
    expect(xref.content).to eq('clause 2121372')
  end
end
