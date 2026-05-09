# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Pass-through block — raw content passed through without processing
    class PassBlock < Block
      def self.semantic_type = :pass

      attribute :block_semantic_type, :string, default: -> { 'pass' }
    end
  end
end
