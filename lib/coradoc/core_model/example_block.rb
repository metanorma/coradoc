# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Example block — a delimited block for examples
    class ExampleBlock < Block
      def self.semantic_type = :example

      attribute :block_semantic_type, :string, default: -> { 'example' }
    end
  end
end
