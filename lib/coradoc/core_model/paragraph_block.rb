# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Paragraph block — a block of prose text
    class ParagraphBlock < Block
      def self.semantic_type = :paragraph
    end
  end
end
