# frozen_string_literal: true

# Replays suite-captured inputs (diff_capture.rb preloader) through the
# PARG artifact and compares trees with the captured Ruby-DSL trees.

$LOAD_PATH.unshift '/Users/mulgogi/src/parsanol/parsanol-ruby/lib'
$LOAD_PATH.unshift File.expand_path('coradoc/lib', __dir__)
$LOAD_PATH.unshift File.expand_path('coradoc-adoc/lib', __dir__)
require 'parsanol/parg'
require 'json'

def deep_str(obj)
  case obj
  when Parsanol::Slice then obj.to_s
  when Hash then obj.transform_keys(&:to_s).transform_values { |v| deep_str(v) }
  when Array then obj.map { |v| deep_str(v) }
  else obj
  end
end

captures = JSON.parse(File.read(ENV.fetch('CAPTURES', '/tmp/diff_captures.json')))
artifact = Parsanol::PARG::Artifact.load(
  File.expand_path('grammars/coradoc-adoc.artifact.json', __dir__)
)

same = same_err = 0
diverged = []
captures.each_with_index do |(input, dsl_tree), i|
  a = begin
    JSON.generate(deep_str(artifact.parse('document', input, mode: :ruby)))
  rescue StandardError => e
    JSON.generate('__error__' => e.class.name)
  end
  d = JSON.generate(dsl_tree)
  if a == d
    dsl_tree.is_a?(Hash) && dsl_tree.key?('__error__') ? same_err += 1 : same += 1
  else
    diverged << [i, input]
  end
end

puts "#{same} identical (+#{same_err} matching errors), #{diverged.size} diverged / #{captures.size}"
File.write('/tmp/diverged.json', JSON.pretty_generate(diverged.map { |i, inp| { 'idx' => i, 'input' => inp } }))
