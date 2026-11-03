# frozen_string_literal: true

require 'coradoc'
require 'coradoc/asciidoc'
require 'coradoc/markdown'

module Coradoc
  # Round-trip property harness for the CoreModel hub.
  #
  # For a source text T in format F the harness checks, per construct:
  #
  #   core1 = parse(T)        T1 = serialize(core1)
  #   core2 = parse(T1)       T2 = serialize(core2)
  #
  #   model stability  projection(core1) == projection(core2)
  #   canonical form   T2 == T1   (T1 is the canonical form of T)
  #
  # See roundtrip/CANONICAL_FORM.md for the policy.
  module Roundtrip
    ROOT = File.expand_path('../..', __dir__)
    REPO_ROOT = File.expand_path('..', ROOT)
    FORMATS = %i[asciidoc markdown].freeze

    autoload :Case, 'coradoc/roundtrip/case'
    autoload :Checker, 'coradoc/roundtrip/checker'
    autoload :Corpus, 'coradoc/roundtrip/corpus'
    autoload :EdgeCases, 'coradoc/roundtrip/edge_cases'
    autoload :Failure, 'coradoc/roundtrip/failure'
    autoload :KnownFailures, 'coradoc/roundtrip/known_failures'
    autoload :Projection, 'coradoc/roundtrip/projection'
    autoload :Snippet, 'coradoc/roundtrip/snippet'
  end
end
