# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Reviewer comment block — a block for reviewer annotations
    class ReviewerBlock < AnnotationBlock
      def self.semantic_type = :reviewer
    end
  end
end
