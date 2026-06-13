# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Handles HorizontalRuleBlock → horizontal_rule node.
      module HorizontalRule
        def self.call(_element, context:)
          Node::HorizontalRule.new
        end
      end
    end
  end
end
