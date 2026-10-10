# frozen_string_literal: true

require 'tmpdir'

module Coradoc
  module Lint
    # Runs rules over the format model trees a SourceGraph exposes.
    # Files parse lazily — only when a rule set exists for their
    # format — so linting a mixed corpus costs nothing for formats
    # without rules.
    class Runner
      def initialize(format: nil, only: nil, except: nil,
                     registry: Coradoc::Lint.registry)
        @format = format
        @only = only
        @except = except
        @registry = registry
      end

      attr_reader :registry

      # @param sources [String, Array<String>, SourceGraph::Graph]
      # @return [Array<Violation>]
      def run(sources)
        graph = build_graph(sources)
        graph.nodes.flat_map { |node| lint_node(node) }
             .sort_by { |v| [v.path, v.rule_id] }
      end

      private

      def build_graph(sources)
        return sources if sources.is_a?(SourceGraph::Graph)

        SourceGraph.build(Array(sources), sidecar: null_sidecar)
      end

      # Lint runs should never silently create cache entries in the
      # user's XDG dir unless persist is explicit.
      def null_sidecar
        SourceGraph::Sidecar.new(File.join(Dir.tmpdir, "coradoc-lint-#{Process.pid}"))
      end

      def lint_node(node)
        format = @format || node.format
        rules = rules_for(format)
        return [] if rules.empty?

        rules.flat_map { |rule| rule.new.check(node.parsed, node.path) }
      rescue Coradoc::UnsupportedFormatError
        []
      end

      # Rules for a format, lazily requiring the format gem's lint
      # ruleset on first sight — mirrors FormatCatalog.lazy_load_format.
      def rules_for(format)
        rules = @registry.for_format(format, only: @only, except: @except)
        return rules unless rules.empty? && !format.nil?

        require "coradoc/#{format}/lint"
        @registry.for_format(format, only: @only, except: @except)
      rescue LoadError
        rules
      end
    end
  end
end
