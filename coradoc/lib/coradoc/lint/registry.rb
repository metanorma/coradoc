# frozen_string_literal: true

module Coradoc
  module Lint
    # Rule selection by format and id. Format gems register their
    # rules at require time.
    class Registry
      def initialize
        @rules = []
      end

      def register(rule)
        raise ArgumentError, "rule #{rule} must declare an id" if rule.id.nil?
        raise ArgumentError, "rule #{rule} must declare a format" if rule.format.nil?

        @rules << rule
        self
      end

      def for_format(format, only: nil, except: nil)
        @rules.select do |rule|
          rule.format == format &&
            (only.nil? || only.include?(rule.id)) &&
            (except.nil? || !except.include?(rule.id))
        end
      end

      def rule_ids(format)
        for_format(format).map(&:id)
      end
    end
  end
end
