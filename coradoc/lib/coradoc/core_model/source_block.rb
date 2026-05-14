# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Specialized block for source code listings
    class SourceBlock < Block
      def self.semantic_type
        :source_code
      end
    end
  end
end
