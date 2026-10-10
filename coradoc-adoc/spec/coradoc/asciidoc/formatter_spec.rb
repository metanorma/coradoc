# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html'

RSpec.describe Coradoc::AsciiDoc::Formatter do
  def fmt(text)
    described_class.call(text)
  end

  [
    "= T\n\n== S\n\ntext here\n",
    "para\n\n----\ncode\n----\n",
    "[source,ruby]\n----\nputs 1\n----\n",
    "* a\n** b\n* c\n",
    ". one\n.. two\n",
    "text with `escaped` marks\n",
    ":attr: val\n\n{attr} used\n",
    "[NOTE]\n====\nnote body\n====\n",
    "|===\n| a | b |\n|===\n",
    "term:: definition\n",
    "include::part.adoc[]\n",
    "'''\n"
  ].each do |sample|
    it "is idempotent for #{sample.inspect[0..40]}" do
      once = fmt(sample)
      expect(fmt(once)).to eq(once)
    end
  end

  it 'collapses inflated inter-block spacing to a single blank line' do
    expect(fmt("para\n\n\n\n----\ncode\n----\n"))
      .to eq("para\n\n[source]\n----\ncode\n----\n")
  end

  it 'strips leading blank lines and keeps exactly one trailing newline' do
    expect(fmt("\n\n\n* a\n* b\n\n\n")).to eq("* a\n* b\n")
  end

  it 'emits [source] without a trailing comma when the language is empty' do
    expect(fmt("----\ncode\n----\n")).to include("[source]\n")
  end

  it 'preserves blank lines inside listing fences' do
    source = "----\na\n\n\nb\n----\n"

    expect(fmt(source)).to eq("[source]\n----\na\n\n\nb\n----\n")
  end

  it 'canonicalizes loose list spacing to tight (documented v1 style)' do
    expect(fmt("* a\n\n* b\n")).to eq("* a\n* b\n")
  end

  it 'round-trips through Coradoc::AsciiDoc.format' do
    expect(Coradoc::AsciiDoc.format("= T\n\n\n\n== S\n\nt\n"))
      .to eq("= T\n\n== S\n\nt\n")
  end
end

RSpec.describe 'FormatModule::Interface#format default' do
  it 'returns nil for formats without a formatter' do
    expect(Coradoc::Html.format('<p>x</p>')).to be_nil
  end
end
