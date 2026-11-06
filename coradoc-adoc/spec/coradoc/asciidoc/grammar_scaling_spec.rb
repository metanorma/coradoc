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

  # A `%i"word"` case-insensitive literal compiles to an unanchored regex with a
  # literal prefilter, so a failed attempt scans the remaining input for the
  # word (a 21 MB document of base64 images took 83 s instead of 9 s).
  it 'writes no case-insensitive literal (%i"...")' do
    offenders = grammar.each_line.with_index(1).filter_map do |line, number|
      code = line.sub(/#.*/, '')
      "#{number}: #{line.strip}" if code.include?('%i"')
    end

    expect(offenders).to be_empty
  end

  it 'matches admonition labels in any letter case and nothing longer' do
    parse = ->(text) { Coradoc::AsciiDoc::Parser::Base.parse(text)[:document] }

    expect(parse.call("nOtE: hi\n").first).to include(admonition_type: 'nOtE')
    expect(parse.call("ADMONITION: hi\n").first).to include(admonition_type: 'ADMONITION')
    expect(parse.call("Tipp: hi\n").first).to have_key(:paragraph)
  end

  it 'parses text without any inline markup byte' do
    text = (1..200).map { |i| "Plain text line #{i} here.\n\n" }.join
    document = Coradoc::AsciiDoc::Parser::Base.parse(text)

    expect(document[:document]).not_to be_empty
  end

  # The inline fast path skips the inline choice at characters that cannot
  # start markup; markup after plain, CJK or mid-word text must still parse.
  describe 'inline markup after skipped text' do
    def parse_lines(text)
      Coradoc::AsciiDoc::Parser::Base.parse("#{text}\n")[:document]
    end

    {
      '日本語*強調*です' => :bold_constrained,
      'abc http://x.y/z ok' => :link,
      'see:footnote:[n] x' => :footnote,
      'x_ term:[a]' => :term_type
    }.each do |text, key|
      it "keeps #{key} in #{text.inspect}" do
        expect(parse_lines(text).inspect).to include(key.to_s)
      end
    end

    it 'keeps inline markup in list item text' do
      expect(parse_lines('* 日本語 _it_ end').inspect).to include('italic_constrained')
    end
  end

  # Table cells are consumed in bulk runs that stop at the active delimiter.
  describe 'table cell boundaries' do
    def table_cells(source)
      document = Coradoc::AsciiDoc::Parser::Base.parse(source)[:document]
      document.flat_map { |node| node[:table][:rows].flat_map { |row| row[:row][:cells] } }
    end

    it 'splits cells at the delimiter and keeps multi-line cell text' do
      cells = table_cells("|===\n| a | b\\|c\nsecond line\n| d\n|===\n")

      expect(cells.map { |cell| cell[:cell][:text].to_s }).to eq([' a ', " b\\|c\nsecond line", ' d'])
    end

    it 'honours a non-pipe delimiter' do
      cells = table_cells("!===\n! x | y ! z\n!===\n")

      expect(cells.map { |cell| cell[:cell][:text].to_s }).to eq([' x | y ', ' z'])
    end

    it 'keeps an inline base64 image line as one cell text' do
      line = "image::data:image/webp;base64,#{'Ab+/9_=' * 40}[]"
      cells = table_cells("|===\n1.1+| \n\n#{line}\n 1.1+| x\n|===\n")

      expect(cells.first[:cell][:text].to_s).to include(line)
    end
  end
end
