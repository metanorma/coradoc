# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trailing empty list items (#139)' do
  it 'round-trips a bare trailing marker as an empty item' do
    adoc = Coradoc.convert("* a\n* b\n*\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).to include("* a\n* b\n* \n")
  end

  it 'does not corrupt the previous item marker' do
    adoc = Coradoc.convert("* a\n* b\n*\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).not_to match(/\n b/)
  end

  it 'keeps ordinary lists intact' do
    adoc = Coradoc.convert("* a\n* b\n* c\n", from: :asciidoc, to: :asciidoc)
    expect(adoc).to include("* a\n* b\n* c\n")
  end
end
