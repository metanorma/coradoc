# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Literal block — a delimited block for preformatted literal text
    class LiteralBlock < Block
      def self.semantic_type = :literal

      attribute :block_semantic_type, :string, default: -> { 'literal' }
    end
  end
end
