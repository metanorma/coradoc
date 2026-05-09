# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Literal block — a delimited block for preformatted literal text
    class LiteralBlock < Block
      def self.semantic_type = :literal
    end
  end
end
