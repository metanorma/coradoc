# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Quote block — a delimited block for quotations
    class QuoteBlock < Block
      def self.semantic_type = :quote

      attribute :attribution, :string
    end
  end
end
