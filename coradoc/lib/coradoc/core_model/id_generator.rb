# frozen_string_literal: true

module Coradoc
  module CoreModel
    module IdGenerator
      def self.generate_from_title(title, parent_id: nil)
        return nil if title.nil? || title.to_s.strip.empty?

        suffix = title.to_s.downcase
                      .gsub(/[^a-z0-9\s]/, '')
                      .gsub(/\s+/, '_')
        # Trim edge underscore runs without end-anchored quantified
        # patterns (CodeQL rb/polynomial-redos).
        suffix = suffix[1..] while suffix.start_with?('_')
        suffix = suffix[0...-1] while suffix.end_with?('_')

        return "_#{suffix}" if parent_id.nil? || parent_id.to_s.strip.empty?

        "#{parent_id}_#{suffix}"
      end
    end
  end
end
