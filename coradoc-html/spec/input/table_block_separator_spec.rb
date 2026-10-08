# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Table/block separation (#151)' do
  it 'separates a paragraph following a table' do
    html = "<table><tbody><tr><td>r1</td></tr></tbody></table>\n<p>The type is X.</p>\n"
    adoc = Coradoc.convert(html, from: :html, to: :asciidoc)
    expect(adoc).to include("|===\n\nThe type is X.")
  end

  it 'separates paragraph and block image after a table' do
    html = "<table><tbody><tr><td><p>Row 1 Col 1</p></td></tr></tbody></table>\n<p>Text before image.</p>\n<img src=\"sample.png\">"
    adoc = Coradoc.convert(html, from: :html, to: :asciidoc)
    expect(adoc).to include("|===\n\nText before image.\n\nimage::sample.png[]")
  end
end
