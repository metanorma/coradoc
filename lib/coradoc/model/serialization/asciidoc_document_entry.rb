# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization
      class AsciidocDocumentEntry
        attr_reader :entry_type, :content, :attributes, :mapping

        def initialize(entry_type:, content:, attributes:, mapping: nil)
          @entry_type = entry_type
          @content = content
          @attributes = attributes
          @mapping = mapping
        end

        def self.parse(type, content, attributes, mapping)
          new(
            entry_type: type.downcase,
            content: content,
            attributes: attributes,
            mapping: mapping,
          )
        end

        def to_asciidoc(*)
          result = []
          unless attributes.empty?
            result << "[#{attributes.map do |k, v|
              "#{k}=\"#{v}\""
            end.join(',')}]"
          end
          result << "#{entry_type}::#{content}"
          result.join("\n")
        end
      end
    end
  end
end
