# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'yaml'
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

  # Raw parse trees of every input, parsed once for all the corpus guards.
  def self.corpus_trees(inputs)
    @corpus_trees ||= inputs.map { |input| Coradoc::AsciiDoc::Parser::Base.parse(input) }
  end

  def corpus_trees
    self.class.corpus_trees(all_inputs)
  end

  def contains_key?(node, *keys)
    case node
    when Hash then keys.all? { |k| node.key?(k) } || node.each_value.any? { |v| contains_key?(v, *keys) }
    when Array then node.any? { |v| contains_key?(v, *keys) }
    else false
    end
  end

  roundtrip_root = File.expand_path('../../../..', __dir__)
  roundtrip = YAML.load_file(File.join(roundtrip_root, 'roundtrip/corpus.yml')).fetch('asciidoc')
                  .flat_map { |glob| Dir[File.join(roundtrip_root, glob)] }.sort.map { |path| File.read(path) }
                  .select { |text| text.bytesize <= 6_000 } # the parser is superlinear: keep the run short
  corpus = JSON.parse(File.read(File.expand_path('../../fixtures/parg_corpus.json', __dir__)))
  inline = [
    "= Title\n\nbody\n",
    "= Title\nJane, Doe <jane@example.org>\n\nbody\n",
    "= Title\n1.0, 2026-01-01: first\n\nbody\n",
    "= Title\nJane, Doe <jane@example.org>\n1.0, 2026-01-01: first\n\n== Section\n\nText.\n",
    "[[hid]]\n= Title With Anchor\n\nbody\n",
    "* a\n* b\n** nested\n",
    "[%reversed]\n. one\n. two\n",
    "[square]\n* x\n",
    "term1::\nterm2:: shared\n\nouter:: o\ninner::: i\n",
    "[%key]\nterm:: def\n+\nattached\n",
    "* item\n+\nattached para\n",
    "*bold* _it_ #hl# `mono` **ub** __ui__ ##uh## ``um`` [.role]#span# [.r]##uspan## x^2^ y~2~\n",
    "link:http://example.org[Text] https://example.org and <<ref,Label>> and xref:other.adoc[Doc]\n",
    "See image:pic.png[Alt,100] and {attr} and \"`quoted`\" '`single`' plus+++<b>raw</b>+++ and pass:[<i>x</i>]\n",
    "Line one +\nLine two\\\n\ncontinued\n",
    "Fact.footnote:[A note] and footnote:fid[Named] and footnote:fid[]\n",
    "stem:[x^2] and latexmath:[y] and asciimath:[z]\n",
    "term:[x] and abbr:[y] and index:term[foo]\n",
    "NOTE: a note\nmore note\n\nWARNING: careful\n",
    "[NOTE]\n====\nexample note\n====\n",
    "|===\n|a |b\n|c |d\n|===\n",
    ".Cap\n[cols=\"1,2\",options=\"header\"]\n|===\n|H1 |H2\n\n2+^.^a|spanned *bold*\n|===\n",
    "[[tid]]\n|===\n|x\n|===\n",
    "image::pic.png[Alt,100,200]\n\n.Fig\n[[fid]]\nimage::b.png[]\n",
    "//\n\n// image::images/419.svg[]\n//\ntext\n//",
    "// c1\n// tag::t[]\ntext\n// end::t[]\n////\nblock\n////\n",
    "include::a.adoc[]\n\ninclude::b.adoc[lines=1..2]\n",
    "<<<\n\ntext\n",
    ":attr: value\n:other: more\n\nbody {attr}\n",
    "[[sid]]\n== Section {#x}\n\ntext\n\n=== Sub\n\nmore\n\n== Another\n",
    "[source,ruby,linenums]\n----\nx = 1\n----\n\n[quote,Author,Source]\n____\nq\n____\n",
    "Plain *bold*\n\n\n\nafter blanks\n"
  ]
  inline_keys = %i[link cross_reference inline_image inline_passthrough attribute_reference typographic_quote
                   hard_line_break footnote bold_constrained italic_constrained highlight_constrained
                   monospace_constrained bold_unconstrained italic_unconstrained highlight_unconstrained
                   monospace_unconstrained span_constrained span_unconstrained superscript subscript stem]

  it 'binds every grammar rule, with all transformer rule modules retired' do
    bindings = Coradoc::AsciiDoc::Bindings
    expect(bindings::ALL.map(&:keys)).to contain_exactly(
      [:header], %i[first_name last_name email], %i[number date remark], [:paragraph],
      [:list_item], [:list], [:unordered], %i[attribute_list unordered], [:ordered], %i[attribute_list ordered],
      %i[dlist_term delimiter], [:definition_list_item], [:definition_list], %i[attribute_list definition_list],
      *bindings::INLINE.map(&:keys), *bindings::TEXT.map(&:keys), *bindings::BLOCK.map(&:keys),
      *bindings::STRUCTURE.map(&:keys), *bindings::MISC.map(&:keys)
    )
    %i[HeaderRules ListRules InlineRules TextRules BlockRules StructuralRules MiscRules].each do |retired|
      expect(Coradoc::AsciiDoc::Transformer.const_defined?(retired, false)).to be(false)
    end
  end

  # Rules the parser never emits were retired without a binding: no grammar
  # production names them (see `as(:example)` etc. in parser/), and neither
  # the adoc suite nor the roundtrip corpus ever matched them.
  it 'never produces the keys of the retired dead rules over the corpus' do
    dead = %i[example audio video reviewer_note text_string glossaries bibliography_entry highlight]
    trees = corpus_trees
    dead.each do |key|
      expect(trees.count { |tree| contains_key?(tree, key) }).to eq(0), "#{key} is emitted"
    end
  end

  it 'exercises each bound text, block, table and attribute rule over the corpus (guards against a vacuous run)' do
    trees = corpus_trees
    %i[text line_break unparsed block admonition_type block_image cell_format cell row cells table section
       document comment_line comment_block page_break tag named positional attribute_array key
       document_attributes include].each do |key|
      expect(trees.count { |tree| contains_key?(tree, key) }).to be >= 1, "no corpus entry exercises #{key}"
    end
    expect(trees.count { |tree| contains_key?(tree, :level, :line_break, :text) }).to be >= 1
  end

  it 'builds ordered, unordered and definition lists through the inflater' do
    doc = bound("* a\n** nested\n\n. one\n. two\n\nterm:: def\n")
    kinds = doc.sections.map(&:class)
    expect(kinds).to eq([Coradoc::AsciiDoc::Model::List::Unordered, Coradoc::AsciiDoc::Model::List::Ordered,
                         Coradoc::AsciiDoc::Model::List::Definition])
    expect(doc.sections.first.items.first.nested).to be_a(Coradoc::AsciiDoc::Model::List::Unordered)
  end

  it 'exercises each bound list rule over the corpus (guards against a vacuous run)' do
    trees = corpus_trees
    %i[list_item unordered ordered definition_list definition_list_item dlist_term].each do |key|
      expect(trees.count { |tree| contains_key?(tree, key) }).to be >= 1, "no corpus entry exercises #{key}"
    end
  end

  it 'exercises each bound inline rule over the corpus (guards against a vacuous run)' do
    trees = corpus_trees
    inline_keys.each do |key|
      expect(trees.count { |tree| contains_key?(tree, key) }).to be >= 1, "no corpus entry exercises #{key}"
    end
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
    hits = corpus_trees.count { |tree| contains_key?(tree, :header) }
    expect(hits).to be >= 3
  end

  define_method(:all_inputs) { corpus + inline + roundtrip }

  (corpus + inline + roundtrip).each_with_index do |input, index|
    it "produces identical models (incl. source lines) for corpus entry #{index}" do
      with = bound(input)
      without = unbound(input)
      expect(dump(with)).to eq(dump(without))
    end
  end
end
