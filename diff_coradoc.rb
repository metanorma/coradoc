# frozen_string_literal: true

# Differential harness for the coradoc-adoc PARG port (#129/#61):
# every corpus input must produce the IDENTICAL tree from the compiled
# artifact and the Ruby DSL parser. Slices normalize to their strings;
# offsets/positions are not part of the contract.

$LOAD_PATH.unshift '/Users/mulgogi/src/parsanol/parsanol-ruby/lib'
$LOAD_PATH.unshift File.expand_path('coradoc/lib', __dir__)
$LOAD_PATH.unshift File.expand_path('coradoc-adoc/lib', __dir__)
require 'parsanol'
require 'parsanol/parg'
require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/asciidoc/parser'

CORPUS = [
  # delimited blocks, every style
  "----\ncode\n----\n",
  "====\nexample\n====\n",
  "____\nquote\n____\n",
  "****\nsidebar\n****\n",
  "++++\npass\n++++\n",
  "....\nliteral\n....\n",
  "--\nopen\n--\n",
  # state fidelity: same run closes, longer opener needs longer close
  "------\ninner ---- stays\n------\n",
  "----\ncode\n------\nstill code\n------\n",
  "```\nplain\n```\n",
  "```ruby\nputs 1\n```\n",
  "````\n```\n````\n",
  # empty lines inside blocks
  "----\na\n\nb\n----\n",
  # PENDING paragraph port (no trailing newline after closer)
  "----\ncode\n----",
  "----\n----\n",
  "```ruby\nputs 1\n```",
  # block headers
  ".Title\n----\ncode\n----",
  "[[id1]]\n----\ncode\n----",
  "[source, ruby]\n----\nx = 1\n----",
  "[role=quote]\n[source]\n----\ncode\n----",
  ".T\n----\nc\n----\n",
  "[[i]]\n----\nc\n----\n",
  "[role=quote]\n[source]\n----\nc\n----\n",
  ".T\n[[i]]\n[role=x]\n----\nc\n----\n",
  ".Title\n[[id]]\n[role=x, name=\"v\"]\n----\ncode\n----",
  # comments / tags / includes
  "// a comment\n",
  "////\nblock comment\n////\n",
  "// tag::section-name[]\n",
  "// end::section-name[]\n",
  "include::file.adoc[]\n",
  "include::file.adoc[leveloffset=1]\n",
  # document mixing
  "\n\n\ntext line\n\n",
  "----\ncode\n----\nafter text\n",
  "// c\n----\ncode\n----\n\n",
  # inline markup
  "some *bold* and _italic_ text\n",
  "**un**constrained and `mono` marks\n",
  "a \"`\" typographic pair\n",
  "xref <<target,Title>> inline\n",
  "link https://example.com/x[] here\n",
  "footnote:[a note] inline\n",
  "stem:[x + y] and term:[t]\n",
  "image:pic.png[] and pass:[raw <b>]\n",
  "hard break +\nnext line\n",
  "[.underline]#under# and [.small]#sm#\n",
  "^sup^ and ~sub~ marks\n",
  "plain text with no markup at all\n",
  "{attr-ref} in text\n",
  "escaped \\\\<< not an xref\n",
  # lists
  "* a\n* b\n",
  "* a\n** nested\n* b\n",
  ". one\n. two\n",
  "- dash item\n",
  "term::\n  definition\n",
  "term:: inline definition\n",
  "a:::: deep\n",
  # admonition
  "NOTE: watch out\n",
  "TIP: this helps\n",
  # list continuation + attached
  "* item\n+\nattached para\n",
  # headers / doc attributes / sections
  "= Document Title\n",
  "= Document Title\nAuthor Name, <a@b.co>\n",
  "= T\nAuthor, Last <e@x.io>\n1.2, 2024-01-01: remark\n",
  ":toc: left\n:sectnums:\n",
  "=== Level 3\n\ntext\n\n== Level 2\n",
  "== A\n\n=== B\n\ndeep\n\n",
  # page break + block image
  "para\n\n<<<\n\n",
  "image::pic.png[]\n",
  ".Caption\nimage::dir/img.png[alt=Hi]\n",
  # bibliography
  "* [[[ref1]]] Some reference text\n",
  "* [[[iso123,ISO 123]]] Reference with doc id\n",
  # tables
  "|===\n| a | b\n| c | d\n|===\n",
  "|===\n| cell with | pipe escaped \\\\| inside\n|===\n",
  ",===\n, comma table\n,===\n",
  "|===\n2+^| spans\n|===\n",
].freeze

def normalize(obj)
  case obj
  when Parsanol::Slice then obj.to_s
  when Hash then obj.transform_values { |v| normalize(v) }
  when Array then obj.map { |v| normalize(v) }
  else obj
  end
end

artifact = Parsanol::PARG::Artifact.load(
  File.expand_path('grammars/coradoc-adoc.artifact.json', __dir__)
)

dsl = Coradoc::AsciiDoc::Parser::Base.new

pass = 0
failures = []
CORPUS.each_with_index do |input, i|
  a_tree = begin
    t = artifact.parse('document', input, mode: :ruby)
    [:ok, normalize(t)]
  rescue StandardError => e
    [:err, "#{e.class}: #{e.message[0, 120]}"]
  end
  d_tree = begin
    t = dsl.parse(input)
    [:ok, normalize(t)]
  rescue StandardError => e
    [:err, "#{e.class}: #{e.message[0, 120]}"]
  end
  if a_tree == d_tree
    pass += 1
  else
    failures << [i, input, a_tree, d_tree]
  end
end

puts "#{pass}/#{CORPUS.size} identical"
failures.each do |i, input, a, d|
  puts "\n=== row #{i}: #{input.inspect}"
  puts "artifact: #{a.inspect[0, 400]}"
  puts "dsl:      #{d.inspect[0, 400]}"
end
exit(failures.empty? ? 0 : 1)
