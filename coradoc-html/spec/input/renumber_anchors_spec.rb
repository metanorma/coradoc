# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'renumber_anchors option (#83)' do
  after { Coradoc::Html.input_config.renumber_anchors = false }

  it 'keeps source ids by default' do
    out = Coradoc.convert('<h2 id="_Toc12345">Intro</h2>', from: :html, to: :asciidoc)
    expect(out).to include('[[_Toc12345]]')
  end

  it 'regenerates ids from titles when enabled' do
    Coradoc::Html.input_config.renumber_anchors = true
    out = Coradoc.convert('<h2 id="_Toc12345">Intro</h2>', from: :html, to: :asciidoc)
    expect(out).not_to include('_Toc')
    expect(out).to include('[[')
    expect(out).to match(/\[\[[a-z0-9_]+\]\]/)
  end

  it 'still deduplicates regenerated ids' do
    Coradoc::Html.input_config.renumber_anchors = true
    out = Coradoc.convert('<h2 id="_Toc1">Same</h2><h2 id="_Toc2">Same</h2>',
                          from: :html, to: :asciidoc)
    ids = out.scan(/\[\[([a-z0-9_]+)\]\]/).flatten
    expect(ids.uniq.size).to eq(ids.size)
  end
end
