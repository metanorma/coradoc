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
require 'json'
require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/asciidoc/parser'

CORPUS = JSON.parse(File.read(File.expand_path('coradoc-adoc/spec/fixtures/parg_corpus.json', __dir__)))

def normalize(obj)
  case obj
  when Parsanol::Slice then obj.to_s
  when Hash then obj.transform_values { |v| normalize(v) }
  when Array then obj.map { |v| normalize(v) }
  else obj
  end
end

artifact = Parsanol::PARG::Artifact.load(
  File.expand_path('coradoc-adoc/grammar/coradoc-adoc.artifact.json', __dir__)
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
