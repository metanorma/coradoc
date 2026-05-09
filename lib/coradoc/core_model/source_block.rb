# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Specialized block for source code listings
    #
    # Represents a source code block with optional language annotation.
    # This is a first-class model type rather than a generic Block with
    # a delimiter_type tag.
    #
    # @example Creating a source code block
    #   block = CoreModel::SourceBlock.new(
    #     content: "puts 'Hello, World!'",
    #     language: "ruby"
    #   )
    class SourceBlock < Block
      def self.semantic_type = :source_code

      attribute :block_semantic_type, :string, default: -> { 'source_code' }
    end
  end
end
