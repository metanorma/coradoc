# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocDocumentEntry
        attr_reader :content, :attributes, :mapping

        def initialize(content:, attributes:, mapping: nil)
          @content = content
          @attributes = attributes
          @mapping = mapping
        end

        def self.parse(type, content, attributes, mapping)
          new(
            content: content,
            attributes: attributes,
            mapping: mapping,
          )
        end
      end
    end
  end
end
