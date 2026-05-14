# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Verse block — a block for verse/poetry with optional attribution
    class VerseBlock < Block
      def self.semantic_type
        :verse
      end

      attribute :attribution, :string
    end
  end
end
