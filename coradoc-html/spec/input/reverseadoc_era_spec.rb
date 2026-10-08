# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ReverseAdoc-era regressions' do
  def conv(html)
    Coradoc.convert(html, from: :html, to: :asciidoc)
  end

  it '#88: bare body text trims HTML-source whitespace' do
    expect(conv("  plain text\n  <h1>h1</h1>")).to include('plain text')
    expect(conv("  plain text\n  <h1>h1</h1>")).not_to include(' plain text ')
  end

  it '#108: link with no text renders no empty []' do
    expect(conv('<p>see <a href="http://example.com"></a> now</p>')).not_to include('[]')
  end

  it '#109: image title becomes the block caption' do
    expect(conv('<p><img src="x.png" title="Figure 1: caption"></p>'))
      .to include(".Figure 1: caption\nimage::x.png[]")
  end

  it '#89: math converts without object dump' do
    out = conv('<p>Converted <math><mi>x</mi></math>, end.</p>')
    expect(out).not_to include('Leptris')
    expect(out).to include('mathml:[<math><mi>x</mi></math>]')
  end

  it '#102: duplicate section ids are deduplicated' do
    adoc = conv('<h2 id="toc_02">A</h2><h2 id="toc_02">B</h2>')
    expect(adoc).to include('[[toc_02]]')
    expect(adoc).to include('[[toc_02_1]]')
  end

  it '#103: empty id produces no empty anchor' do
    expect(conv('<h2 id="">A</h2>')).not_to include('[[]]')
  end
end
