# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Pass-through block — raw content passed through without processing
    class PassBlock < Block
      def self.semantic_type = :pass
    end
  end
end
