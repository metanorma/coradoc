# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../support/legacy_header_rules'

RSpec.describe 'AsciiDoc bound-vs-unbound differential (M3 binding seam)' do
  def parse_with(transformer, input)
    split = Coradoc::AsciiDoc::Parser::FrontmatterParser.call(input)
    transformer.transform(Coradoc::AsciiDoc::Parser::Base.parse(split.body))
  end

  def bound(input)
    parse_with(Coradoc::AsciiDoc::Transformer, input)
  end

  # The retired hand-written rules, bindings off.
  def unbound(input)
    LegacyHeaderRules.transformer.with_bindings(nil) { parse_with(LegacyHeaderRules.transformer, input) }
  end

  # Structural dump of a model tree (class, source_line and every
  # attribute); lutaml's own to_yaml cannot serialize this model set.
  def dump(value)
    case value
    when Coradoc::AsciiDoc::Model::Base
      [value.class.name, value.source_line,
       value.class.attributes.each_key.to_h { |attr| [attr, dump(value.public_send(attr))] }]
    when Array then value.map { |item| dump(item) }
    else value.respond_to?(:to_str) ? value.to_str : value
    end
  end

  def contains_key?(node, *keys)
    case node
    when Hash then keys.all? { |k| node.key?(k) } || node.each_value.any? { |v| contains_key?(v, *keys) }
    when Array then node.any? { |v| contains_key?(v, *keys) }
    else false
    end
  end

  corpus = JSON.parse(File.read(File.expand_path('../../fixtures/parg_corpus.json', __dir__)))
  inline = [
    "= Title\n\nbody\n",
    "= Title\nJane, Doe <jane@example.org>\n\nbody\n",
    "= Title\n1.0, 2026-01-01: first\n\nbody\n",
    "= Title\nJane, Doe <jane@example.org>\n1.0, 2026-01-01: first\n\n== Section\n\nText.\n",
    "[[hid]]\n= Title With Anchor\n\nbody\n"
  ]

  it 'binds header, author, revision and paragraph, with no rule module left for the header' do
    expect(Coradoc::AsciiDoc::Bindings::ALL.map(&:keys)).to contain_exactly(
      [:header], %i[first_name last_name email], %i[number date remark], [:paragraph]
    )
    expect(Coradoc::AsciiDoc::Transformer.const_defined?(:HeaderRules, false)).to be(false)
  end

  it 'builds the header, author and revision through the inflater' do
    doc = bound("= Title\nJane, Doe <jane@example.org>\n1.0, 2026-01-01: first\n\nbody\n")
    header = doc.header
    expect(header).to be_a(Coradoc::AsciiDoc::Model::Header)
    expect(header.author).to be_a(Coradoc::AsciiDoc::Model::Author)
    expect(header.author.email).to eq('jane@example.org')
    expect(header.revision.number).to eq('1.0')
  end

  it 'builds paragraphs through the inflater' do
    paragraph = bound("first line\nsecond line\n").sections.first
    expect(paragraph).to be_a(Coradoc::AsciiDoc::Model::Paragraph)
    expect(paragraph.content.size).to eq(2)
  end

  it 'exercises the bound header rule over the corpus (guards against a vacuous run)' do
    hits = (corpus + inline).count do |input|
      contains_key?(Coradoc::AsciiDoc::Parser::Base.parse(input), :header)
    end
    expect(hits).to be >= 3
  end

  (corpus + inline).each_with_index do |input, index|
    it "produces identical models (incl. source lines) for corpus entry #{index}" do
      with = bound(input)
      without = unbound(input)
      expect(dump(with)).to eq(dump(without))
    end
  end
end
