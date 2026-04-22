# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Registry for transform rules.
      #
      # Manages registration and lookup of rules for OOXML element types.
      # Rules are checked in priority order (highest first).
      # Falls back to NullRule which raises ArgumentError.
      #
      # Follows Open/Closed Principle: new rules are added by registering,
      # not by modifying the registry class.
      class RuleRegistry
        def initialize
          @rules = []
        end

        # Register a rule instance
        #
        # @param rule [Rule] the rule to register
        # @return [self]
        def register(rule)
          unless rule.is_a?(Rule)
            raise ArgumentError,
                  "Expected Rule, got #{rule.class}"
          end

          @rules << rule
          @rules.sort_by! { |r| -r.priority }
          self
        end

        # Find the first rule that matches the element
        #
        # @param element [Object] OOXML element to find a rule for
        # @return [Rule] matching rule
        # @raise [ArgumentError] if no rule matches
        def find_rule(element)
          @rules.find { |r| r.matches?(element) } ||
            raise(ArgumentError, "No transform rule registered for #{element.class}")
        end

        # Check if any rule matches the element
        #
        # @param element [Object] element to check
        # @return [Boolean]
        def matches?(element)
          @rules.any? { |r| r.matches?(element) }
        end

        # Number of registered rules
        # @return [Integer]
        def size
          @rules.size
        end
      end
    end
  end
end
