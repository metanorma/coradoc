# frozen_string_literal: true

require 'yaml'

module Coradoc
  module Roundtrip
    # Cases that violate a round-trip property today, each with a reason.
    # The harness fails on any failure NOT listed, and on any listed case
    # that now passes, so the list can only shrink toward empty.
    class KnownFailures
      FILE = File.join(ROOT, 'known_failures.yml')

      # @param entries [Hash{String=>String}] case id => reason
      def initialize(entries = YAML.safe_load_file(FILE) || {})
        @entries = entries
      end

      # Rewrites the file so it lists exactly the cases failing now.
      # Reasons are placeholders ("untriaged") for a person to replace.
      #
      # @param cases [Array<Case>]
      def self.write_baseline(cases, file: FILE)
        checker = Checker.new
        entries = cases.sort_by(&:id).filter_map do |kase|
          failure = checker.call(kase)
          [kase.id, "untriaged: #{failure.stage} at #{failure.path}"] if failure
        end.to_h
        File.write(file, YAML.dump(entries))
        entries.size
      end

      def include?(case_id) = @entries.key?(case_id)

      def reason(case_id) = @entries[case_id]

      def ids = @entries.keys
    end
  end
end
