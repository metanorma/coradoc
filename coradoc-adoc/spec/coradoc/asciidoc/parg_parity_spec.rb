# frozen_string_literal: true

require 'spec_helper'
require 'parsanol/parg'
require 'json'

RSpec.describe 'PARG artifact parity with the Ruby DSL' do
  # The .parg port of the AsciiDoc grammar (coradoc-adoc/grammar/)
  # must produce trees identical to the Ruby-DSL parser for every
  # corpus document. Slices normalize to their strings; offsets and
  # positions are not part of the contract. Regenerate the artifact
  # with `parsanol-parg compile coradoc-adoc/grammar/coradoc-adoc.parg`
  # after editing the grammar.
  artifact_path = File.expand_path('../../../grammar/coradoc-adoc.artifact.json', __dir__)
  corpus_path = File.expand_path('../../fixtures/parg_corpus.json', __dir__)

  def normalize(obj)
    case obj
    when Parsanol::Slice then obj.to_s
    when Hash then obj.transform_values { |v| normalize(v) }
    when Array then obj.map { |v| normalize(v) }
    else obj
    end
  end

  def parse_outcome(parser)
    [:ok, normalize(parser.call)]
  rescue StandardError => e
    [:err, "#{e.class}: #{e.message[0, 120]}"]
  end

  artifact = Parsanol::PARG::Artifact.load(artifact_path)
  dsl = Coradoc::AsciiDoc::Parser::Base.new
  corpus = JSON.parse(File.read(corpus_path))

  corpus.each_with_index do |input, i|
    it "parses corpus entry #{i} identically" do
      a_tree = parse_outcome(-> { artifact.parse('document', input, mode: :ruby) })
      d_tree = parse_outcome(-> { dsl.parse(input) })
      expect(a_tree).to eq(d_tree)
    end
  end
end
