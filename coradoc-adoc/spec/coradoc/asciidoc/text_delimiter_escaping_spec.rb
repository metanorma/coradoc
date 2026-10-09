# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Text delimiter escaping (#92)' do
  def conv(html)
    Coradoc.convert(html, from: :html, to: :asciidoc)
  end

  it 'escapes unconstrained delimiter runs in plain text' do
    expect(conv('<p>a __literal__ pair</p>')).to eq('a \\_\\_literal\\_\\_ pair')
  end

  it 'escapes space-flanked constrained pairs' do
    expect(conv('<p>see *this* here</p>')).to eq('see \\*this\\* here')
    expect(conv('<p>an _em_ candidate</p>')).to eq('an \\_em\\_ candidate')
  end

  it 'escapes a closing delimiter followed by punctuation' do
    expect(conv('<p>see *this*, ok</p>')).to eq('see \\*this\\*, ok')
  end

  it 'escapes backticks anywhere' do
    expect(conv('<p>run `cmd` now</p>')).to eq('run \\`cmd\\` now')
  end

  it 'leaves intraword single delimiters alone' do
    expect(conv('<p>foo_bar_baz and 2 * 3</p>')).to eq('foo_bar_baz and 2 * 3')
  end

  # Blocked on the parse-side \X handling (see #281): the adoc parser
  # keeps the backslash and drops the escaped character, so escaped
  # output does not yet reparse to itself.
  it 'keeps escaped output stable across an adoc reparse' do
    pending 'parse-side \X escape handling (see #281)'
    out = conv('<p>a __literal__ pair</p>')
    again = Coradoc.convert(out, from: :asciidoc, to: :asciidoc)
    expect(again).to eq(out)
  end
end
