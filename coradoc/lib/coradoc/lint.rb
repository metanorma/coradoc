# frozen_string_literal: true

module Coradoc
  # Model-driven linting (#165).
  #
  # Rules live in the FORMAT gems and check the format-specific model
  # tree — never raw text, never a homogenized CoreModel. Each rule
  # declares its format and its check; the framework selects rules by
  # format and runs them against the parsed tree a SourceGraph node
  # exposes (parsing lazily, only files actually linted).
  #
  #   require "coradoc/asciidoc"          # or any format gem you lint
  #   violations = Coradoc::Lint.run("doc.adoc")
  #   violations.each { |v| puts "#{v.path}:#{v.line} [#{v.rule_id}] #{v.message}" }
  #
  # Format gems must be required (or +format:+ passed) — extension
  # detection only sees registered formats, like the rest of Coradoc.
  module Lint
    autoload :Violation, "#{__dir__}/lint/violation"
    autoload :Rule, "#{__dir__}/lint/rule"
    autoload :Registry, "#{__dir__}/lint/registry"
    autoload :Runner, "#{__dir__}/lint/runner"

    class << self
      def registry
        @registry ||= Registry.new
      end

      # Lint files (or an existing SourceGraph) with the rules
      # registered for each file's format.
      #
      # @param sources [String, Array<String>, SourceGraph::Graph]
      # @param format [Symbol, nil] force a format instead of
      #   detecting from the extension
      # @param only [Array<Symbol>] restrict to these rule ids
      # @param except [Array<Symbol>] skip these rule ids
      # @return [Array<Violation>]
      def run(sources, format: nil, only: nil, except: nil)
        Runner.new(format: format, only: only, except: except).run(sources)
      end
    end
  end
end
