# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Verse block — a block for verse/poetry with optional attribution
    class VerseBlock < Block
      def self.semantic_type = :verse

      attribute :block_semantic_type, :string, default: -> { 'verse' }

      attribute :attribution, :string
    end
  end
end
