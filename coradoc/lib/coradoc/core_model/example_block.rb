# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Example block — a delimited block for examples
    class ExampleBlock < Block
      def self.semantic_type
        :example
      end
    end
  end
end
