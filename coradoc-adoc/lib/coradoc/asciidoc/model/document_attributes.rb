# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Container for document-level attributes.
      #
      # DocumentAttributes holds key-value pairs that define document metadata
      # and configuration options. These are the `:key: value` declarations at
      # the top of an AsciiDoc file.
      #
      # @!attribute [r] data
      #   @return [Array<Attribute>] Array of attribute key-value pairs
      #
      # @example Access attributes as hash
      #   attrs = Coradoc::AsciiDoc::Model::DocumentAttributes.new
      #   attrs.data << Coradoc::AsciiDoc::Model::Attribute.new("author", "John Doe")
      #   attrs.to_hash # => {"author" => "John Doe"}
      #
      # @example Get specific attribute
      #   value = attrs.get_attribute("author")
      #
      class DocumentAttributes < Base
        attribute :data, Attribute, collection: true

        def to_hash
          return {} if data.nil?

          data.each_with_object({}) do |attribute, hash|
            hash[attribute.key.to_s] = attribute.value
          end
        end

        def get_attribute(name)
          return nil if data.nil?

          attribute = data.find { |attr| attr.key.to_s == name.to_s }
          attribute&.value
        end
      end
    end
  end
end
