# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Base class for OOXML → CoreModel transform rules.
      #
      # Each rule handles one OOXML element type and produces a CoreModel
      # node. Rules are registered in RuleRegistry and dispatched by the
      # ToCoreModel orchestrator.
      #
      # Subclasses must implement:
      #   - matches?(element) → true if this rule handles the element
      #   - apply(element, context) → CoreModel node or Array of nodes
      #
      # @example Implementing a custom rule
      #   class MyRule < Rule
      #     def matches?(element)
      #       element.is_a?(Uniword::Wordprocessingml::MyElement)
      #     end
      #
      #     def apply(element, context)
      #       Coradoc::CoreModel::Block.new(
      #         element_type: 'paragraph',
      #         content: element.text
      #       )
      #     end
      #   end
      class Rule
        # Check if this rule handles the given element
        #
        # @param element [Object] OOXML element to check
        # @return [Boolean]
        def matches?(element)
          raise NotImplementedError, "#{self.class}#matches? not implemented"
        end

        # Transform an OOXML element to a CoreModel node
        #
        # @param element [Object] OOXML element to transform
        # @param context [Context] shared transform context
        # @return [Coradoc::CoreModel::Base, Array, String, nil]
        def apply(element, context)
          raise NotImplementedError, "#{self.class}#apply not implemented"
        end

        # Rule priority — higher priority rules are checked first.
        # Override in subclasses when needed.
        #
        # @return [Integer]
        def priority
          0
        end
      end
    end
  end
end
