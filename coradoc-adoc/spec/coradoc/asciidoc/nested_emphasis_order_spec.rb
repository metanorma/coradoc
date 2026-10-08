# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested emphasis ordering (#159)' do
  it 'normalizes italic-wrapping-bold to bold-outer/italic-inner' do
    adoc = Coradoc.convert("_*text*_\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).to include('*_text_*')
  end

  it 'keeps bold-outer/italic-inner stable' do
    adoc = Coradoc.convert("*_other_*\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).to include('*_other_*')
  end

  it 'does not escape markers inside the normalized pair' do
    adoc = Coradoc.convert("_*text*_\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).not_to include('\\*')
  end

  it 'leaves single emphasis constrained' do
    adoc = Coradoc.convert("*bold* and _em_\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).to include('*bold*').and include('_em_')
  end
end
