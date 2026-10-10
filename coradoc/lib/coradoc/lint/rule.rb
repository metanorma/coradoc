# frozen_string_literal: true

module Coradoc
  module Lint
    # Base class for lint rules. Subclasses (in the format gems)
    # declare:
    #
    #   id     [String]  stable rule code, e.g. 'ADOC001'
    #   format [Symbol]  registered format the rule applies to
    #   check(document, path) [Array<Violation>] inspect the
    #     format-specific model tree
    #
    # Rules encapsulate their own traversal of the format model —
    # the framework never switches on node types (OCP: a new rule is
    # a new file, nothing else changes).
    class Rule
      class << self
        attr_reader :id, :format

        private

        def rule_id(id)
          @id = id
        end

        def applies_to(format)
          @format = format
        end
      end

      def id
        self.class.id
      end

      def build_violation(path:, message:, line: nil, severity: :warning)
        Violation.new(rule_id: id, path: path, line: line,
                      message: message, severity: severity)
      end
    end
  end
end
