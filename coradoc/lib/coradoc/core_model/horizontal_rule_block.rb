# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Horizontal rule — a thematic break between sections
    class HorizontalRuleBlock < Block
      def self.semantic_type
        :horizontal_rule
      end
    end
  end
end
