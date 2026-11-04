# frozen_string_literal: true

require 'spec_helper'

# coradoc#308: the native engine matches a single-byte `%xNN` terminal with an
# unanchored regex search, so when that byte is absent from the rest of the
# input every attempt scans to the end of the document and parse time grows
# quadratically. The quoted-string form ("^") is matched in place. Ranges
# (%x41-5A) are unaffected.
RSpec.describe 'coradoc-adoc grammar scaling' do
  grammar = File.read(File.expand_path('../../../grammar/coradoc-adoc.parg', __dir__))

  it 'writes no single-byte terminal as %xNN (use a quoted string)' do
    offenders = grammar.each_line.with_index(1).filter_map do |line, number|
      code = line.sub(/#.*/, '')
      "#{number}: #{line.strip}" if code.match?(/%x[0-9A-Fa-f]{2}(?![0-9A-Fa-f-])/)
    end

    expect(offenders).to be_empty
  end

  it 'parses text without any inline markup byte' do
    text = (1..200).map { |i| "Plain text line #{i} here.\n\n" }.join
    document = Coradoc::AsciiDoc::Parser::Base.parse(text)

    expect(document[:document]).not_to be_empty
  end
end
